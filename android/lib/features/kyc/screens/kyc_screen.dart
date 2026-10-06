import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../../core/models/vendor.dart';
import '../../../core/providers/vendors_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../auth/screens/login_screen.dart';

class KycScreen extends ConsumerWidget {
  const KycScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vendorId = ref.watch(currentVendorIdProvider);

    if (vendorId == null) return const Scaffold(body: Center(child: Text('Not logged in')));

    final vendorAsync = ref.watch(vendorDetailProvider(vendorId));

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: RefreshIndicator(
        onRefresh: () async {
          HapticFeedback.lightImpact();
          ref.read(vendorDetailProvider(vendorId).notifier).refresh();
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            SliverAppBar(
              expandedHeight: 120.0,
              floating: true,
              pinned: true,
              elevation: 0,
              backgroundColor: AppColors.primary,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                title: const Text(
                  'My KYC & Documents',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                  ),
                ),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
            ),
            
            vendorAsync.when(
              loading: () => const SliverToBoxAdapter(child: _KycShimmer()),
              error: (e, _) => SliverToBoxAdapter(child: Center(child: Text('Error: $e'))),
              data: (vendor) => SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverToBoxAdapter(
                  child: AnimationLimiter(
                    child: Column(
                      children: AnimationConfiguration.toStaggeredList(
                        duration: const Duration(milliseconds: 375),
                        childAnimationBuilder: (widget) => SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(child: widget),
                        ),
                        children: [
                          _ProfileCard(vendor: vendor),
                          const SizedBox(height: 16),
                          _DocumentsSection(vendor: vendor),
                          const SizedBox(height: 80), // Padding for FAB
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: vendorAsync.valueOrNull != null
          ? FloatingActionButton.extended(
              onPressed: () {
                HapticFeedback.mediumImpact();
                context.push('/kyc/upload');
              },
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload Document'),
            )
          : null,
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Shimmer Loading States
// ──────────────────────────────────────────────────────────────────────────────

class _KycShimmer extends StatelessWidget {
  const _KycShimmer();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Shimmer.fromColors(
          baseColor: AppColors.shimmer,
          highlightColor: AppColors.shimmerHighlight,
          child: Card(
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Shimmer.fromColors(
          baseColor: AppColors.shimmer,
          highlightColor: AppColors.shimmerHighlight,
          child: Container(
            height: 24,
            width: 150,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(3, (index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Shimmer.fromColors(
            baseColor: AppColors.shimmer,
            highlightColor: AppColors.shimmerHighlight,
            child: Card(
              child: Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        )),
      ],
    );
  }
}


class _ProfileCard extends StatelessWidget {
  final Vendor vendor;
  const _ProfileCard({required this.vendor});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(vendor.legalName,
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                StatusChip.vendorStatus(vendor.status.name.toUpperCase()),
              ],
            ),
            if (vendor.tradeName != null && vendor.tradeName!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('T/A: ${vendor.tradeName}',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            if (vendor.pan != null) _DataRow('PAN', vendor.pan!),
            if (vendor.gstin != null) _DataRow('GSTIN', vendor.gstin!),
            if (vendor.udyamNumber != null) _DataRow('UDYAM', vendor.udyamNumber!),
            _DataRow('Email', vendor.email),
            _DataRow('Phone', vendor.phone),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'To update core details, please upload a new authoritative document (GST or Udyam).',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  final String label;
  final String value;
  const _DataRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _DocumentsSection extends StatelessWidget {
  final Vendor vendor;
  const _DocumentsSection({required this.vendor});

  @override
  Widget build(BuildContext context) {
    final docs = vendor.documents;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Uploaded Documents',
                style: Theme.of(context).textTheme.titleSmall),
            if (docs.any((d) => d.status.isProcessing))
              TextButton.icon(
                onPressed: () => context.push('/kyc/status/${vendor.id}'),
                icon: const Icon(Icons.analytics_outlined, size: 16),
                label: const Text('View OCR Status'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (docs.isEmpty)
          const _EmptyDocsState()
        else
          ...docs.map((d) => _DocTile(doc: d)),
      ],
    );
  }
}

class _EmptyDocsState extends StatelessWidget {
  const _EmptyDocsState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border.all(color: AppColors.divider, style: BorderStyle.dash),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(Icons.drive_folder_upload,
              size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text('No documents uploaded',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            'Upload your Udyam (MSME) or GSTIN certificates to start the automated KYC process.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _DocTile extends StatelessWidget {
  final VendorDocument doc;
  const _DocTile({required this.doc});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    doc.type.replaceAll('_', ' '),
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
                StatusChip.documentStatus(doc.status.name.toUpperCase()),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  doc.status == DocumentStatus.parsed ? Icons.check_circle_outline : Icons.schedule,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Uploaded ${DateFormat('dd MMM yyyy').format(doc.uploadedAt)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            if (doc.certificateNumber != null) ...[
              const SizedBox(height: 6),
              Text(
                'No: ${doc.certificateNumber}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
            if (doc.isExpired || doc.isExpiringSoon) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: doc.isExpired
                      ? AppColors.failed.withAlpha(20)
                      : AppColors.pending.withAlpha(20),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  doc.isExpired ? 'Expired Document' : 'Expiring Soon',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: doc.isExpired ? AppColors.failed : AppColors.pending,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
