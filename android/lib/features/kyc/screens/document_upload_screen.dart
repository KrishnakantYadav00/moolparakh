// lib/features/kyc/screens/document_upload_screen.dart
//
// Document upload screen — implements the PRD §5.7 pre-signed URL flow:
//   1. App calls POST /api/documents/presign  → { url, key }
//   2. App sends PUT {presignedUrl} {bytes}   → directly to S3/R2
//   3. App calls POST /api/documents          → records the document in DB
//
// PRD §5.7:
//   "Direct upload bypasses the backend EC2 instance — reduces latency by
//    40–70% (one fewer network hop). The backend never touches the raw file bytes."
//
// Supported document types match DocumentType enum in prisma/schema.prisma.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as p;
import '../../../core/api/api_client.dart';
import '../../../core/models/vendor.dart';
import '../../../core/providers/demo_mode_provider.dart';
import '../../../core/providers/vendors_list_provider.dart';
import '../../../core/providers/vendors_provider.dart';
import '../../../core/services/demo_data.dart';
import '../../../core/theme/app_theme.dart';

// Supported document types — mirrors DocumentType enum in schema.prisma
const _docTypes = [
  'GST_CERTIFICATE',
  'UDYAM_CERTIFICATE',
  'PAN_CARD',
  'CANCELLED_CHEQUE',
  'BANK_STATEMENT',
  'ISO_CERTIFICATE',
  'INSURANCE_DOCUMENT',
  'OTHER',
];

String _docTypeLabel(String t) => t
    .replaceAll('_', ' ')
    .split(' ')
    .map((w) {
      if (w.isEmpty) return w;
      return w[0].toUpperCase() + w.substring(1).toLowerCase();
    })
    .join(' ');

class DocumentUploadScreen extends ConsumerStatefulWidget {
  final String vendorId;
  const DocumentUploadScreen({super.key, required this.vendorId});

  @override
  ConsumerState<DocumentUploadScreen> createState() =>
      _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends ConsumerState<DocumentUploadScreen> {
  File? _file;
  String _docType = _docTypes.first;
  bool _uploading = false;
  double _progress = 0;
  String? _error;
  bool _done = false;

  Future<bool> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status.isPermanentlyDenied) {
      _showPermissionDialog('Camera');
      return false;
    }
    return status.isGranted;
  }

  void _showPermissionDialog(String type) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$type Permission Required'),
        content: Text(
          'Please enable $type permission in app settings to upload documents.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickCamera() async {
    if (!await _requestCameraPermission()) return;
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (picked != null) setState(() => _file = File(picked.path));
    } catch (e) {
      setState(() => _error = 'Failed to capture image: $e');
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );
      if (result?.files.single.path != null) {
        setState(() => _file = File(result!.files.single.path!));
      }
    } catch (e) {
      setState(() => _error = 'Failed to pick file: $e');
    }
  }

  String _mimeType(File f) {
    final ext = p.extension(f.path).toLowerCase();
    switch (ext) {
      case '.pdf':
        return 'application/pdf';
      case '.png':
        return 'image/png';
      default:
        return 'image/jpeg';
    }
  }

  Future<void> _upload() async {
    if (_file == null) return;

    setState(() {
      _uploading = true;
      _progress = 0;
      _error = null;
    });

    final isDemo = ref.read(isDemoModeProvider);
    if (isDemo) {
      for (double pr = 0.25; pr <= 1.0; pr += 0.25) {
        await Future.delayed(const Duration(milliseconds: 250));
        if (mounted) setState(() => _progress = pr);
      }
      final newDoc = VendorDocument(
        id: 'doc-demo-${DateTime.now().millisecondsSinceEpoch}',
        type: _docType,
        status: DocumentStatus.parsed,
        certificateNumber: 'CERT-${DateTime.now().millisecond}',
        issuingAuthority: 'Ministry of Corporate Affairs / GSTN',
        uploadedAt: DateTime.now(),
        expirationDate: DateTime.now().add(const Duration(days: 365)),
        confidence: 0.96,
      );
      for (var i = 0; i < demoVendors.length; i++) {
        final v = demoVendors[i];
        if (v.id == widget.vendorId) {
          demoVendors[i] = Vendor(
            id: v.id,
            legalName: v.legalName,
            tradeName: v.tradeName,
            email: v.email,
            phone: v.phone,
            pan: v.pan,
            gstin: v.gstin,
            cin: v.cin,
            udyamNumber: v.udyamNumber,
            msmeCategory: v.msmeCategory,
            city: v.city,
            state: v.state,
            categories: v.categories,
            contactName: v.contactName,
            contactRole: v.contactRole,
            status: v.status,
            buyerFlagNote: v.buyerFlagNote,
            onboardedAt: v.onboardedAt,
            trustScore: v.trustScore,
            trustHistory: v.trustHistory,
            verifications: v.verifications,
            documents: [newDoc, ...v.documents],
            events: [
              VendorEvent(
                id: 'ev-doc-${DateTime.now().millisecondsSinceEpoch}',
                kind: VendorEventKind.document,
                title: 'Document Uploaded',
                detail: '$_docType uploaded and verified.',
                at: DateTime.now(),
              ),
              ...v.events,
            ],
          );
          break;
        }
      }
      ref.invalidate(vendorsListProvider);
      if (mounted) {
        setState(() {
          _done = true;
          _uploading = false;
        });
      }
      return;
    }

    try {
      final fileName = p.basename(_file!.path);
      final mimeType = _mimeType(_file!);
      final fileSize = await _file!.length();

      // Step 1 — get pre-signed URL
      final presignResult = await ApiClient.instance.presignUpload(
        vendorId: widget.vendorId,
        fileName: fileName,
        mimeType: mimeType,
        documentType: _docType,
      );

      final presignedUrl = presignResult['url'] as String;
      final fileKey = presignResult['key'] as String;

      // Step 2 — upload directly to R2/S3
      await ApiClient.instance.uploadToPresignedUrl(
        presignedUrl,
        _file!,
        onProgress: (sent, total) {
          setState(() => _progress = sent / total);
        },
      );

      // Step 3 — record in DB
      await ApiClient.instance.recordDocument(
        vendorId: widget.vendorId,
        fileKey: fileKey,
        mimeType: mimeType,
        fileSize: fileSize,
        documentType: _docType,
      );

      // Refresh vendor detail so KYC screen is up to date
      ref.read(vendorDetailProvider(widget.vendorId).notifier).refresh();

      setState(() {
        _done = true;
        _uploading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _uploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Document')),
      body: SafeArea(
        child: _done ? _SuccessView(vendorId: widget.vendorId) : _buildForm(),
      ),
    );
  }

  Widget _buildForm() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ── Document type selector ─────────────────────────────────────────
        Text('Document Type', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _docType,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.category_outlined),
          ),
          items: _docTypes
              .map(
                (t) =>
                    DropdownMenuItem(value: t, child: Text(_docTypeLabel(t))),
              )
              .toList(),
          onChanged: _uploading ? null : (v) => setState(() => _docType = v!),
        ),

        if (_docType == 'UDYAM_CERTIFICATE') ...[
          const SizedBox(height: 8),
          Text(
            'Ensure Udyam Registration Number (URN) format UDYAM-XX-00-0000000 is clearly visible for automatic verification.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.primary),
          ),
        ],
        if (_docType == 'GST_CERTIFICATE') ...[
          const SizedBox(height: 8),
          Text(
            'Ensure the 15-character GSTIN is visible. Both English and bilingual (Hindi/English) certificates are supported.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.primary),
          ),
        ],

        const SizedBox(height: 24),

        // ── File picker ────────────────────────────────────────────────────
        Text('File', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),

        if (_file == null)
          _PickerPlaceholder(onCamera: _pickCamera, onFile: _pickFile)
        else
          _FilePreview(
            file: _file!,
            onClear: () => setState(() => _file = null),
          ),

        const SizedBox(height: 24),

        // ── Progress bar ───────────────────────────────────────────────────
        if (_uploading) ...[
          LinearProgressIndicator(value: _progress),
          const SizedBox(height: 8),
          Text(
            _progress < 0.05
                ? 'Getting upload URL…'
                : _progress < 1.0
                ? 'Uploading ${(_progress * 100).toStringAsFixed(0)}%…'
                : 'Saving record…',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
        ],

        // ── Error ──────────────────────────────────────────────────────────
        if (_error != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.failed.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _error!,
              style: const TextStyle(color: AppColors.failed, fontSize: 13),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // ── Upload button ──────────────────────────────────────────────────
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: (_file != null && !_uploading) ? _upload : null,
            icon: _uploading
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.cloud_upload_outlined),
            label: Text(_uploading ? 'Uploading…' : 'Upload Document'),
          ),
        ),

        const SizedBox(height: 16),

        // Info note about the upload flow
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '🔒 Your document is uploaded directly to secure cloud storage. '
            'The backend never receives your file bytes — only a reference key.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.primary.withAlpha(200),
            ),
          ),
        ),
      ],
    );
  }
}

class _PickerPlaceholder extends StatelessWidget {
  final VoidCallback onCamera;
  final VoidCallback onFile;
  const _PickerPlaceholder({required this.onCamera, required this.onFile});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.primary.withAlpha(80),
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _PickOption(
              icon: Icons.camera_alt_outlined,
              label: 'Camera',
              onTap: onCamera,
            ),
          ),
          Container(width: 1, height: 80, color: AppColors.divider),
          Expanded(
            child: _PickOption(
              icon: Icons.folder_open_outlined,
              label: 'File / Gallery',
              onTap: onFile,
            ),
          ),
        ],
      ),
    );
  }
}

class _PickOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _PickOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: AppColors.primary),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilePreview extends StatelessWidget {
  final File file;
  final VoidCallback onClear;
  const _FilePreview({required this.file, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final ext = p.extension(file.path).toLowerCase();
    final isImage = ['.jpg', '.jpeg', '.png'].contains(ext);

    return Container(
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (isImage)
            Positioned.fill(child: Image.file(file, fit: BoxFit.cover))
          else
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.picture_as_pdf,
                    size: 48,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    p.basename(file.path),
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: onClear,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(4),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  final String vendorId;
  const _SuccessView({required this.vendorId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_done_outlined,
              size: 72,
              color: AppColors.verified,
            ),
            const SizedBox(height: 16),
            Text(
              'Uploaded Successfully',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Your document is being processed by the OCR pipeline. '
              'Trust score will update once extraction is complete.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.pushReplacement('/kyc/status/$vendorId'),
              icon: const Icon(Icons.list_alt_outlined),
              label: const Text('View Document Status'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => context.pop(),
              child: const Text('Back to KYC'),
            ),
          ],
        ),
      ),
    );
  }
}
