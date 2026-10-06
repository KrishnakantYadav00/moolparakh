// lib/features/rfq/screens/rfq_list_screen.dart
//
// RFQ list — shows open RFQs the supplier can bid on.
// This is the primary reason the supplier has a mobile app:
//   PRD §9.1.7: "suppliers receive RFQ time-sensitive alerts while at
//   trade fairs or on factory floors — they cannot sit at a desktop portal."

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../../core/models/rfq.dart';
import '../../../core/providers/rfq_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/status_chip.dart';

class RfqListScreen extends ConsumerWidget {
  const RfqListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allRfqsAsync = ref.watch(rfqListProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: RefreshIndicator(
        onRefresh: () async {
          HapticFeedback.lightImpact();
          ref.read(rfqListProvider.notifier).refresh();
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
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
                  'Procurement Bids',
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

            allRfqsAsync.when(
              loading: () => const SliverToBoxAdapter(child: _RfqListShimmer()),
              error: (e, _) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Center(
                    child: Text(
                      'Error: $e',
                      style: const TextStyle(color: AppColors.failed),
                    ),
                  ),
                ),
              ),
              data: (all) => all.isEmpty
                  ? const SliverFillRemaining(child: _EmptyRfqState())
                  : SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          return AnimationConfiguration.staggeredList(
                            position: index,
                            duration: const Duration(milliseconds: 375),
                            child: SlideAnimation(
                              verticalOffset: 50.0,
                              child: FadeInAnimation(
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _RfqCard(rfq: all[index]),
                                ),
                              ),
                            ),
                          );
                        }, childCount: all.length),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Shimmer Loading States
// ──────────────────────────────────────────────────────────────────────────────

class _RfqListShimmer extends StatelessWidget {
  const _RfqListShimmer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(
          5,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Shimmer.fromColors(
              baseColor: AppColors.shimmer,
              highlightColor: AppColors.shimmerHighlight,
              child: Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RfqCard extends StatelessWidget {
  final Rfq rfq;
  const _RfqCard({required this.rfq});

  @override
  Widget build(BuildContext context) {
    final remaining = rfq.closesAt.difference(DateTime.now());
    final isUrgent = remaining.inHours < 24 && !rfq.isClosed;

    return Hero(
      tag: 'rfq-card-${rfq.id}',
      child: Material(
        color: Colors.transparent,
        child: Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => context.push('/rfq/${rfq.id}'),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          rfq.title,
                          style: Theme.of(context).textTheme.titleSmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusChip(
                        label: rfq.status.label,
                        color: rfq.status.isOpen
                            ? AppColors.verified
                            : AppColors.textSecondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    rfq.reference,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.primary),
                  ),
                  const SizedBox(height: 8),

                  // Spec summary
                  Row(
                    children: [
                      _SpecPill(
                        '${rfq.spec.quantity} ${rfq.spec.unit}',
                        Icons.inventory_2_outlined,
                      ),
                      const SizedBox(width: 8),
                      if (rfq.spec.item.isNotEmpty)
                        _SpecPill(rfq.spec.item, Icons.category_outlined),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Footer row
                  Row(
                    children: [
                      if (rfq.isClosed)
                        const Icon(
                          Icons.lock_outline,
                          size: 14,
                          color: AppColors.textSecondary,
                        )
                      else if (isUrgent)
                        const Icon(
                          Icons.timer_outlined,
                          size: 14,
                          color: AppColors.riskHigh,
                        )
                      else
                        const Icon(
                          Icons.schedule_outlined,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          rfq.isClosed
                              ? 'Closed'
                              : 'Closes ${_formatRemaining(remaining)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isUrgent && !rfq.isClosed
                                ? AppColors.riskHigh
                                : AppColors.textSecondary,
                            fontWeight: isUrgent && !rfq.isClosed
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                      Text(
                        '${rfq.bids.length} bid${rfq.bids.length == 1 ? '' : 's'}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatRemaining(Duration d) {
    if (d.isNegative) return 'Closed';
    if (d.inHours < 1) return 'in ${d.inMinutes}m';
    if (d.inDays < 1) return 'in ${d.inHours}h';
    return 'in ${d.inDays}d';
  }
}

class _SpecPill extends StatelessWidget {
  final String text;
  final IconData icon;
  const _SpecPill(this.text, this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyRfqState extends StatelessWidget {
  const _EmptyRfqState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.request_quote_outlined,
              size: 72,
              color: AppColors.textSecondary.withAlpha(120),
            ),
            const SizedBox(height: 16),
            Text(
              'No RFQs available',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'New procurement requests will appear here. '
              'You\'ll receive a push notification when a buyer issues an RFQ.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
