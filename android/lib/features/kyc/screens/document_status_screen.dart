// lib/features/kyc/screens/document_status_screen.dart
//
// Document status tracker — polls GET /api/documents/{vendorId} every 5s
// while any document is in PROCESSING_OCR state.
//
// PRD §14.3 — API contract endpoint:
//   GET /api/documents/{vendorId} — owned by P4 (Lambda writes status), P1 stores
//   Target response time: < 200 ms per poll

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/api/api_client.dart';
import '../../../core/models/vendor.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/status_chip.dart';

class DocumentStatusScreen extends ConsumerStatefulWidget {
  final String vendorId;
  const DocumentStatusScreen({super.key, required this.vendorId});

  @override
  ConsumerState<DocumentStatusScreen> createState() =>
      _DocumentStatusScreenState();
}

class _DocumentStatusScreenState extends ConsumerState<DocumentStatusScreen> {
  List<VendorDocument>? _docs;
  bool _loading = true;
  String? _error;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final raw = await ApiClient.instance.listDocuments(widget.vendorId);
      final docs = raw.map((j) => VendorDocument.fromJson(j)).toList();
      setState(() {
        _docs = docs;
        _loading = false;
      });
      _schedulePollIfNeeded(docs);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _schedulePollIfNeeded(List<VendorDocument> docs) {
    _pollTimer?.cancel();
    final hasProcessing = docs.any(
      (d) => d.status == DocumentStatus.processingOcr,
    );
    if (hasProcessing) {
      // PRD §14.4 mock server protocol: poll every 5 seconds
      _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _load());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Document Status'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text('Error: $_error'))
          : _docs!.isEmpty
          ? const _EmptyState()
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _docs!.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _DocCard(doc: _docs![i]),
              ),
            ),
    );
  }
}

class _DocCard extends StatelessWidget {
  final VendorDocument doc;
  const _DocCard({required this.doc});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.description_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    doc.type.replaceAll('_', ' '),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                StatusChip.documentStatus(doc.status.name.toUpperCase()),
              ],
            ),

            // Spinner for in-progress
            if (doc.status.isProcessing) ...[
              const SizedBox(height: 10),
              const LinearProgressIndicator(),
              const SizedBox(height: 4),
              Text(
                'OCR pipeline is processing your document…',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.primary),
              ),
            ],

            if (doc.status == DocumentStatus.parsed) ...[
              const SizedBox(height: 10),
              const Divider(),
              const SizedBox(height: 6),
              if (doc.certificateNumber != null)
                _FieldRow('Certificate No.', doc.certificateNumber!),
              if (doc.issuingAuthority != null)
                _FieldRow('Issuing Authority', doc.issuingAuthority!),
              if (doc.issueDate != null)
                _FieldRow(
                  'Issue Date',
                  DateFormat('dd MMM yyyy').format(doc.issueDate!),
                ),
              if (doc.expirationDate != null)
                _FieldRow(
                  'Expiry Date',
                  DateFormat('dd MMM yyyy').format(doc.expirationDate!),
                  highlight: doc.isExpired || doc.isExpiringSoon,
                  highlightColor: doc.isExpired
                      ? AppColors.failed
                      : AppColors.pending,
                ),
              if (doc.confidence != null && doc.confidence! > 0)
                _FieldRow(
                  'OCR Confidence',
                  '${(doc.confidence! * 100).toStringAsFixed(1)}%',
                ),
            ],

            if (doc.status == DocumentStatus.failed) ...[
              const SizedBox(height: 8),
              Text(
                'Extraction failed. Please re-upload a clearer image.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.failed),
              ),
            ],

            const SizedBox(height: 6),
            Text(
              'Uploaded ${DateFormat('dd MMM yyyy HH:mm').format(doc.uploadedAt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  final Color? highlightColor;
  const _FieldRow(
    this.label,
    this.value, {
    this.highlight = false,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: highlight ? highlightColor : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: AppColors.textSecondary),
          SizedBox(height: 12),
          Text('No documents uploaded yet'),
        ],
      ),
    );
  }
}
