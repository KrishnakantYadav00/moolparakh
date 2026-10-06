// lib/features/kyc/screens/kyc_screen.dart
//
// KYC tab — supplier's own compliance profile.
// Shows documents list, upload button, and deep-links to document status.
//
// PRD §14.3 — API contract:
//   GET  /api/documents/{vendorId}     → list documents (owned by P4, via P1)
//   POST /api/documents/presign        → step 1 of upload flow

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/models/vendor.dart';
import '../../../core/providers/vendors_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../../shared/widgets/trust_score_badge.dart';
import '../../auth/screens/login_screen.dart';

class KycScreen extends ConsumerWidget {
  const KycScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vendorId = ref.watch(currentVendorIdProvider);
    if (vendorId == null) {
      return const Center(child: Text('Not logged in'));
    }

    final vendorAsync = ref.watch(vendorDetailProvider(vendorId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('My KYC'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(vendorDetailProvider(vendorId).notifier).refresh(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/kyc/upload?vendorId=$vendorId'),
        icon: const Icon(Icons.upload_file),
        label: const Text('Upload Document'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: vendorAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (vendor) => RefreshIndicator(
          onRefresh: () async {
            ref
                .read(vendorDetailProvider(vendorId).notifier)
                .refresh();
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              _ProfileHeader(vendor: vendor),
              const SizedBox(height: 16),
              _VerificationSection(vendor: vendor),
              const SizedBox(height: 16),
              _DocumentsSection(vendor: vendor, vendorId: vendorId),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Profile header
// ──────────────────────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final Vendor vendor;
  const _ProfileHeader({required this.vendor});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary,
                  radius: 24,
                  child: Text(
                    vendor.displayName.isNotEmpty
                        ? vendor.displayName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(vendor.displayName,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      if (vendor.tradeName != null &&
                          vendor.tradeName != vendor.legalName)
                        Text(vendor.legalName,
                            style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                TrustScoreBadge(
                  score: vendor.trustScore?.overallScore ?? 0,
                  size: 52,
                  strokeWidth: 5,
                ),
              ],
            ),
            const Divider(height: 24),
            _InfoRow(Icons.location_city_outlined,
                '${vendor.city}, ${vendor.state}'),
            _InfoRow(Icons.email_outlined, vendor.email),
            _InfoRow(Icons.phone_outlined, vendor.phone),
            _InfoRow(Icons.badge_outlined,
                '${vendor.msmeCategory.label} MSME'),
            if (vendor.gstin != null)
              _InfoRow(Icons.business_outlined, 'GSTIN: ${vendor.gstin}'),
            if (vendor.udyamNumber != null)
              _InfoRow(
                  Icons.verified_outlined, 'Udyam: ${vendor.udyamNumber}'),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Verification section
// ──────────────────────────────────────────────────────────────────────────────

class _VerificationSection extends StatelessWidget {
  final Vendor vendor;
  const _VerificationSection({required this.vendor});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Government Verifications',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            ...VerificationType.values.map((type) {
              final rec = vendor.verifications
                  .where((v) => v.type == type)
                  .firstOrNull;
              return _VerifRow(type: type, record: rec);
            }),
          ],
        ),
      ),
    );
  }
}

class _VerifRow extends StatelessWidget {
  final VerificationType type;
  final VerificationRecord? record;
  const _VerifRow({required this.type, this.record});

  @override
  Widget build(BuildContext context) {
    final status = record?.status.name.toUpperCase() ?? 'PENDING';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
              child: Text(type.label,
                  style: Theme.of(context).textTheme.bodyMedium)),
          StatusChip.verification(status),
          if (record?.verifiedAt != null) ...[
            const SizedBox(width: 8),
            Text(
              DateFormat('dd MMM yy').format(record!.verifiedAt!),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Documents section
// ──────────────────────────────────────────────────────────────────────────────

class _DocumentsSection extends StatelessWidget {
  final Vendor vendor;
  final String vendorId;
  const _DocumentsSection(
      {required this.vendor, required this.vendorId});

  @override
  Widget build(BuildContext context) {
    final docs = vendor.documents;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Uploaded Documents',
                    style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                Text('${docs.length} file${docs.length == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 12),
            if (docs.isEmpty)
              const _EmptyDocState()
            else
              ...docs.map((d) => _DocumentTile(doc: d, vendorId: vendorId)),
          ],
        ),
      ),
    );
  }
}

class _DocumentTile extends StatelessWidget {
  final VendorDocument doc;
  final String vendorId;
  const _DocumentTile({required this.doc, required this.vendorId});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => context.push('/kyc/status/$vendorId'),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.divider),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.description_outlined,
                  size: 20, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doc.type.replaceAll('_', ' '),
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    if (doc.expirationDate != null)
                      Text(
                        'Expires: ${DateFormat('dd MMM yyyy').format(doc.expirationDate!)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: doc.isExpired
                              ? AppColors.failed
                              : doc.isExpiringSoon
                                  ? AppColors.pending
                                  : AppColors.textSecondary,
                        ),
                      ),
                    if (doc.confidence != null && doc.confidence! > 0)
                      Text(
                        'OCR confidence: ${(doc.confidence! * 100).toStringAsFixed(0)}%',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusChip.documentStatus(doc.status.name.toUpperCase()),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyDocState extends StatelessWidget {
  const _EmptyDocState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Icon(Icons.upload_file_outlined,
                size: 48, color: AppColors.textSecondary.withAlpha(120)),
            const SizedBox(height: 8),
            Text(
              'No documents uploaded yet',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap + to upload GST, Udyam, or other certificates',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
