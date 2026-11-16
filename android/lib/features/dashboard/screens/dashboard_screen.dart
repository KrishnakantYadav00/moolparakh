import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/main_shell.dart';
import '../../../core/models/vendor.dart';
import '../../../core/models/rfq.dart';
import '../../../core/providers/vendors_list_provider.dart';
import '../../../core/providers/rfq_provider.dart';
import '../../../core/theme/app_theme.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vendorsAsync = ref.watch(vendorsListProvider);
    final rfqsAsync = ref.watch(rfqListProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: RefreshIndicator(
        onRefresh: () async {
          HapticFeedback.lightImpact();
          ref.invalidate(vendorsListProvider);
          ref.invalidate(rfqListProvider);
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverAppBar(
              floating: true,
              pinned: true,
              elevation: 0,
              backgroundColor: AppColors.surface,
              iconTheme: const IconThemeData(color: AppColors.textPrimary),
              leading: IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  mainShellScaffoldKey.currentState?.openDrawer();
                },
              ),
              title: const Text(
                'Good morning, Procurement',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  letterSpacing: -0.5,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(
                    Icons.notifications_outlined,
                    color: AppColors.textPrimary,
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    context.go('/home/notifications');
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined, color: AppColors.textPrimary),
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    context.push('/settings');
                  },
                ),
              ],
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Text(
                  'Your supplier network at a glance.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
              ),
            ),
            vendorsAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => SliverFillRemaining(
                child: Center(child: Text('Error loading network data', style: TextStyle(color: AppColors.failed))),
              ),
              data: (vendors) {
                return rfqsAsync.when(
                  loading: () => const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (err, _) => SliverFillRemaining(
                    child: Center(child: Text('Error loading RFQs', style: TextStyle(color: AppColors.failed))),
                  ),
                  data: (rfqs) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildKpiGrid(context, vendors, rfqs),
                            const SizedBox(height: 24),
                            _buildRiskSnapshot(context, vendors),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiGrid(BuildContext context, List<Vendor> vendors, List<Rfq> rfqs) {
    final verifiedCount = vendors.where((v) => v.status == VendorStatus.verified).length;
    final totalTrust = vendors.fold<int>(0, (sum, v) => sum + (v.trustScore?.overallScore ?? 0));
    final avgTrust = vendors.isEmpty ? 0.0 : totalTrust / vendors.length;
    final openRfqs = rfqs.where((r) => r.status == RfqStatus.open).length;
    final complianceRiskCount = vendors
        .expand((v) => v.documents)
        .where((d) => d.isExpired || d.isExpiringSoon)
        .length;

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _KpiCard(
          title: 'Verified Vendors',
          value: verifiedCount.toString(),
          subtitle: 'vendors verified',
          icon: Icons.verified,
          color: Colors.teal,
          onTap: () => context.go('/home/vendors'),
        ),
        _KpiCard(
          title: 'Avg Trust Score',
          value: avgTrust.toStringAsFixed(1),
          subtitle: 'network average',
          icon: Icons.speed,
          color: Colors.teal,
          onTap: () => context.go('/home/vendors'),
        ),
        _KpiCard(
          title: 'Compliance Risk',
          value: complianceRiskCount.toString(),
          subtitle: 'certifications need attention',
          icon: Icons.warning_amber_rounded,
          color: Colors.orange,
          onTap: () => context.go('/home/kyc'),
        ),
        _KpiCard(
          title: 'Active RFQs',
          value: openRfqs.toString(),
          subtitle: 'collecting quotes',
          icon: Icons.description_outlined,
          color: Colors.blue,
          onTap: () => context.go('/home/rfq'),
        ),
      ],
    );
  }

  Widget _buildRiskSnapshot(BuildContext context, List<Vendor> vendors) {
    final critical = vendors.where((v) => (v.trustScore?.overallScore ?? 0) < 25).length;
    final high = vendors.where((v) => (v.trustScore?.overallScore ?? 0) >= 25 && (v.trustScore?.overallScore ?? 0) < 50).length;
    final medium = vendors.where((v) => (v.trustScore?.overallScore ?? 0) >= 50 && (v.trustScore?.overallScore ?? 0) < 75).length;
    final low = vendors.where((v) => (v.trustScore?.overallScore ?? 0) >= 75).length;
    final total = vendors.isEmpty ? 1 : vendors.length;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFEEEEEE)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Supplier Risk Snapshot', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      SizedBox(height: 2),
                      Text('Risk banding derived from trust scores.', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => context.go('/home/intelligence'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Intelligence', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _RiskBar('CRITICAL', critical, total, const Color(0xFFB71C1C)),
            _RiskBar('HIGH', high, total, const Color(0xFFE65100)),
            _RiskBar('MEDIUM', medium, total, const Color(0xFFF57F17)),
            _RiskBar('LOW', low, total, const Color(0xFF2E7D32)),
          ],
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _RiskBar extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;

  const _RiskBar(this.label, this.count, this.total, this.color);

  @override
  Widget build(BuildContext context) {
    final flex = (count / total * 100).clamp(0, 100).toInt();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
          ),
          Expanded(
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFFEEEEEE),
                borderRadius: BorderRadius.circular(4),
              ),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: flex / 100 == 0 ? 0.01 : flex / 100,
                child: Container(
                  decoration: BoxDecoration(
                    color: flex > 0 ? color : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 30,
            child: Text(count.toString(), textAlign: TextAlign.right, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}
