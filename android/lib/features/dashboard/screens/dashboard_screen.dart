import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../../core/models/vendor.dart';
import '../../../core/providers/vendors_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../../shared/widgets/trust_score_badge.dart';
import '../../auth/screens/login_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Optimize rebuilds: only watch the vendor ID first to avoid rebuilding
    // the whole Scaffold when vendor details change.
    final vendorId = ref.watch(currentVendorIdProvider);

    if (vendorId == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: RefreshIndicator(
        onRefresh: () async {
          HapticFeedback.lightImpact();
          ref.read(vendorDetailProvider(vendorId).notifier).refresh();
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            // Premium Sliver App Bar
            SliverAppBar(
              expandedHeight: 120.0,
              floating: true,
              pinned: true,
              elevation: 0,
              backgroundColor: AppColors.primary,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                title: const Text(
                  'Dashboard',
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
              actions: [
                IconButton(
                  icon: const Icon(
                    Icons.notifications_none,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    context.push('/notifications');
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    ref.read(currentVendorIdProvider.notifier).state = null;
                    context.go('/login');
                  },
                ),
              ],
            ),

            // Staggered Content Area (Isolating Vendor Watch)
            SliverToBoxAdapter(
              child: _VendorDashboardContent(vendorId: vendorId),
            ),
          ],
        ),
      ),
    );
  }
}

class _VendorDashboardContent extends ConsumerWidget {
  final String vendorId;
  const _VendorDashboardContent({required this.vendorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vendorAsync = ref.watch(vendorDetailProvider(vendorId));

    return vendorAsync.when(
      loading: () => const _DashboardShimmer(),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            'Failed to load dashboard: $e',
            style: const TextStyle(color: AppColors.failed),
          ),
        ),
      ),
      data: (vendor) => AnimationLimiter(
        child: Column(
          children: AnimationConfiguration.toStaggeredList(
            duration: const Duration(milliseconds: 375),
            childAnimationBuilder: (widget) => SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(child: widget),
            ),
            children: [
              const SizedBox(height: 16),
              _WelcomeHeader(vendor: vendor),
              const SizedBox(height: 24),
              _TrustScoreHeroCard(vendor: vendor),
              const SizedBox(height: 24),
              _Section43bAlertCard(vendor: vendor),
              const SizedBox(height: 24),
              _ActionCardsGrid(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Shimmer Loading States (Performance Architect)
// ──────────────────────────────────────────────────────────────────────────────

class _DashboardShimmer extends StatelessWidget {
  const _DashboardShimmer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Shimmer.fromColors(
            baseColor: AppColors.shimmer,
            highlightColor: AppColors.shimmerHighlight,
            child: Container(
              height: 24,
              width: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Shimmer.fromColors(
            baseColor: AppColors.shimmer,
            highlightColor: AppColors.shimmerHighlight,
            child: Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Shimmer.fromColors(
                  baseColor: AppColors.shimmer,
                  highlightColor: AppColors.shimmerHighlight,
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Shimmer.fromColors(
                  baseColor: AppColors.shimmer,
                  highlightColor: AppColors.shimmerHighlight,
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Components
// ──────────────────────────────────────────────────────────────────────────────

class _WelcomeHeader extends StatelessWidget {
  final Vendor vendor;
  const _WelcomeHeader({required this.vendor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  vendor.legalName,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          StatusChip.vendorStatus(vendor.status.name.toUpperCase()),
        ],
      ),
    );
  }
}

class _TrustScoreHeroCard extends StatelessWidget {
  final Vendor vendor;
  const _TrustScoreHeroCard({required this.vendor});

  @override
  Widget build(BuildContext context) {
    final score = vendor.trustScore?.overallScore ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          context.push('/trust-score');
        },
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withAlpha(15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(color: AppColors.divider.withAlpha(100)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'MoolParakh Trust Score',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  Icon(Icons.chevron_right, color: AppColors.textSecondary),
                ],
              ),
              const SizedBox(height: 24),
              // RepaintBoundary isolates the chart drawing from the rest of the list scroll
              RepaintBoundary(
                child: Hero(
                  tag: 'trust-badge-${vendor.id}',
                  child: Material(
                    color: Colors.transparent,
                    child: TrustScoreBadge(
                      score: score,
                      size: 120,
                      strokeWidth: 10,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _getScoreMessage(score),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getScoreMessage(int score) {
    if (score == 0)
      return 'Upload your Udyam and GSTIN to calculate your score.';
    if (score >= 80)
      return 'Excellent! You are highly attractive to enterprise buyers. Keep your documents updated.';
    if (score >= 50)
      return 'Your score is moderate. Ensure no GST filing delays to improve your ranking.';
    return 'Action Required: Your low score severely impacts your bid win rate under Section 43B(h).';
  }
}

class _Section43bAlertCard extends StatelessWidget {
  final Vendor vendor;
  const _Section43bAlertCard({required this.vendor});

  @override
  Widget build(BuildContext context) {
    final docs = vendor.documents;
    final hasUdyam = docs.any(
      (d) => d.type == 'UDYAM_CERTIFICATE' && d.status == DocumentStatus.parsed,
    );
    final isCritical =
        !hasUdyam || (vendor.trustScore?.overallScore ?? 100) < 50;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isCritical
              ? AppColors.failed.withAlpha(15)
              : AppColors.primary.withAlpha(15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCritical
                ? AppColors.failed.withAlpha(50)
                : AppColors.primary.withAlpha(50),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isCritical ? Icons.warning_amber_rounded : Icons.info_outline,
              color: isCritical ? AppColors.failed : AppColors.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Section 43B(h) Compliance',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isCritical ? AppColors.failed : AppColors.primary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasUdyam
                        ? 'Your MSME Udyam status is active. Buyers can claim deductions on time.'
                        : 'Missing Udyam Certificate! Buyers may reject your bids to avoid 43B(h) tax penalties. Upload immediately.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isCritical
                          ? AppColors.failed.withAlpha(200)
                          : AppColors.textPrimary,
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

class _ActionCardsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _ActionCard(
              title: 'KYC & Docs',
              icon: Icons.verified_user_outlined,
              color: AppColors.trustExcellent,
              onTap: () {
                HapticFeedback.lightImpact();
                context.push('/kyc');
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _ActionCard(
              title: 'My Bids',
              icon: Icons.gavel_outlined,
              color: AppColors.primaryLight,
              onTap: () {
                HapticFeedback.lightImpact();
                context.go('/rfqs'); // Switch tab
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(30)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: color,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
