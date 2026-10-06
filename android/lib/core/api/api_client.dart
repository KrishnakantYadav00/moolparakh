// lib/core/api/api_client.dart
//
// Dio-based HTTP client for the MoolParakh backend.
//
// PRD §5.7 — "Dio: Upload progress stream via DioAdapter; retry interceptor;
//              cleaner error handling than http package"
//
// Base URL comes from SharedPreferences (configurable in Settings screen),
// falling back to localhost:5000 for dev.
//
// PRD §14.3 — critical API endpoints this client calls:
//   POST /api/documents/presign       → presignUpload
//   GET  /api/documents/{vendorId}    → listDocuments
//   GET  /api/vendors/{id}            → getVendor   (also returns trust score)
//   GET  /api/vendors                 → listVendors
//   GET  /api/rfqs                    → listRfqs
//   GET  /api/rfqs/{id}               → getRfq
//   POST /api/rfqs/{id}/bids          → submitBid
//   GET  /api/notifications           → listNotifications
//   PATCH /api/notifications/{id}/read
//   PATCH /api/notifications/read-all

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Errors
// ──────────────────────────────────────────────────────────────────────────────

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

// ──────────────────────────────────────────────────────────────────────────────
// Client
// ──────────────────────────────────────────────────────────────────────────────

class ApiClient {
  static const _defaultBase = 'http://10.0.2.2:5000/api'; // Android emulator → localhost
  static const _prefsKey = 'api_base_url';

  late final Dio _dio;
  late String _base;

  ApiClient._();
  static final ApiClient instance = ApiClient._();

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _base = prefs.getString(_prefsKey) ?? _defaultBase;

    _dio = Dio(BaseOptions(
      baseUrl: _base,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Readable request/response logs in debug builds
    assert(() {
      _dio.interceptors.add(PrettyDioLogger(
        requestHeader: false,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        compact: true,
      ));
      return true;
    }());

    // Convert Dio errors into ApiException
    _dio.interceptors.add(InterceptorsWrapper(
      onError: (e, handler) {
        if (e.response != null) {
          final data = e.response!.data;
          final msg = (data is Map && data['error'] != null)
              ? data['error'].toString()
              : e.message ?? 'Unknown error';
          handler.reject(
            DioException(
              requestOptions: e.requestOptions,
              error: ApiException(msg, statusCode: e.response!.statusCode),
              response: e.response,
              type: e.type,
            ),
          );
        } else {
          handler.next(e);
        }
      },
    ));
  }

  /// Update the base URL and persist it.
  Future<void> setBaseUrl(String url) async {
    _base = url;
    _dio.options.baseUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, url);
  }

  String get currentBaseUrl => _base;

  // ─── Vendors ──────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> listVendors() async {
    final res = await _get('/vendors');
    return (res as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getVendor(String id) async {
    return await _get('/vendors/$id') as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createVendor(
      Map<String, dynamic> body) async {
    return await _post('/vendors', body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateVendor(
      String id, Map<String, dynamic> body) async {
    final res = await _dio.patch('/vendors/$id', data: body);
    return res.data as Map<String, dynamic>;
  }

  // ─── Documents ────────────────────────────────────────────────────────────

  /// PRD §5.7 — pre-signed URL flow step 1:
  ///   App calls POST /api/documents/presign → backend returns { url, key }
  Future<Map<String, dynamic>> presignUpload({
    required String vendorId,
    required String fileName,
    required String mimeType,
    required String documentType,
  }) async {
    return await _post('/documents/presign', {
      'vendorId': vendorId,
      'fileName': fileName,
      'mimeType': mimeType,
      'documentType': documentType,
    }) as Map<String, dynamic>;
  }

  /// PRD §5.7 — pre-signed URL flow step 2:
  ///   App sends PUT directly to S3 using the pre-signed URL.
  ///   This BYPASSES the backend — request goes straight to AWS.
  Future<void> uploadToPresignedUrl(
    String presignedUrl,
    File file, {
    void Function(int sent, int total)? onProgress,
  }) async {
    final uploadDio = Dio(); // bare Dio, no base URL or auth headers
    final bytes = await file.readAsBytes();
    await uploadDio.put(
      presignedUrl,
      data: Stream.fromIterable([bytes]),
      options: Options(
        headers: {
          'Content-Length': bytes.length,
          'Content-Type': 'application/octet-stream',
        },
        sendTimeout: const Duration(minutes: 5),
      ),
      onSendProgress: onProgress,
    );
  }

  /// Step 3: record the document in the DB after upload.
  Future<Map<String, dynamic>> recordDocument({
    required String vendorId,
    required String fileKey,
    required String mimeType,
    required int fileSize,
    required String documentType,
  }) async {
    return await _post('/documents', {
      'vendorId': vendorId,
      'fileKey': fileKey,
      'mimeType': mimeType,
      'fileSize': fileSize,
      'type': documentType,
    }) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> listDocuments(String vendorId) async {
    final res = await _get('/documents/$vendorId');
    return (res as List).cast<Map<String, dynamic>>();
  }

  // ─── RFQs ─────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> listRfqs() async {
    final res = await _get('/rfqs');
    return (res as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getRfq(String id) async {
    return await _get('/rfqs/$id') as Map<String, dynamic>;
  }

  /// Supplier submits a bid on an open RFQ.
  Future<Map<String, dynamic>> submitBid(
    String rfqId, {
    required String vendorId,
    required double pricePerUnit,
    required int deliveryDays,
    required int trustScoreAtBid,
    String? notes,
  }) async {
    return await _post('/rfqs/$rfqId/bids', {
      'vendorId': vendorId,
      'pricePerUnit': pricePerUnit,
      'deliveryDays': deliveryDays,
      'trustScoreAtBid': trustScoreAtBid,
      if (notes != null) 'notes': notes,
    }) as Map<String, dynamic>;
  }

  // ─── Notifications ────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> listNotifications() async {
    final res = await _get('/notifications');
    return (res as List).cast<Map<String, dynamic>>();
  }

  Future<void> markNotificationRead(String id) async {
    await _dio.patch('/notifications/$id/read');
  }

  Future<void> markAllNotificationsRead() async {
    await _dio.patch('/notifications/read-all');
  }

  // ─── Intelligence ─────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> listDisruptionEvents() async {
    final res = await _get('/intelligence/events');
    return (res as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> disruptionEventsForVendor(
      String vendorId) async {
    final res = await _get('/intelligence/events/$vendorId');
    return (res as List).cast<Map<String, dynamic>>();
  }

  // ─── Health ───────────────────────────────────────────────────────────────

  Future<bool> checkHealth() async {
    try {
      final res = await _dio.get(
        _base.replaceAll('/api', '/health'),
        options: Options(receiveTimeout: const Duration(seconds: 5)),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ─── Private helpers ──────────────────────────────────────────────────────

  Future<dynamic> _get(String path) async {
    try {
      final res = await _dio.get(path);
      return res.data;
    } on DioException catch (e) {
      throw e.error ?? ApiException(e.message ?? 'Request failed');
    }
  }

  Future<dynamic> _post(String path, Map<String, dynamic> body) async {
    try {
      final res = await _dio.post(path, data: body);
      return res.data;
    } on DioException catch (e) {
      throw e.error ?? ApiException(e.message ?? 'Request failed');
    }
  }
}
