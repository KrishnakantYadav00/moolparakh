import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../../../core/models/vendor.dart';
import '../../../core/providers/intelligence_provider.dart';
import '../../../core/providers/vendors_list_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/main_shell.dart';

class IntelligenceScreen extends ConsumerWidget {
  const IntelligenceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(intelligenceProvider);
    final vendorsAsync = ref.watch(vendorsListProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: RefreshIndicator(
        onRefresh: () async {
          HapticFeedback.lightImpact();
          ref.invalidate(intelligenceProvider);
          ref.invalidate(vendorsListProvider);
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
                onPressed: () => mainShellScaffoldKey.currentState?.openDrawer(),
              ),
              title: const Text(
                'Supplier Intelligence',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                  letterSpacing: -0.5,
                ),
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.withAlpha(80)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text('LIVE',
                          style: TextStyle(
                              color: Colors.green,
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),

            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── DISRUPTION HEATMAP ──────────────────────────
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: _SectionHeader(
                      title: 'Disruption Heatmap',
                      subtitle: 'Signal density by region and event type over the last 30 days.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  const _DisruptionHeatmap(),

                  const SizedBox(height: 24),

                  // ── RISK LEADERBOARD ────────────────────────────
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: _SectionHeader(
                      title: 'Risk Leaderboard',
                      subtitle: 'Suppliers ranked by current risk exposure.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  vendorsAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text('Error: $e',
                          style: const TextStyle(color: AppColors.failed)),
                    ),
                    data: (vendors) => vendors.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(
                              child: Text('No vendors in the network yet.',
                                  style: TextStyle(color: AppColors.textSecondary)),
                            ),
                          )
                        : _RiskLeaderboard(vendors: vendors),
                  ),

                  const SizedBox(height: 24),

                  // ── LIVE DISRUPTION FEED ─────────────────────────
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: _SectionHeader(
                      title: 'Live Disruption Feed',
                      subtitle: 'Events matched to your suppliers from the monitored news corpus.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  eventsAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text('Error: $e',
                          style: const TextStyle(color: AppColors.failed)),
                    ),
                    data: (events) => events.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.fromLTRB(20, 0, 20, 40),
                            child: _EmptyFeed(),
                          )
                        : _DisruptionFeed(events: events),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Header
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 2),
        Text(subtitle,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Disruption Heatmap
// ─────────────────────────────────────────────────────────────────────────────

class _DisruptionHeatmap extends StatelessWidget {
  const _DisruptionHeatmap();

  static const _regions = [
    'Western India',
    'Southern India',
    'Northern India',
    'Eastern India',
    'South-East Asia',
    'Gulf & Middle East',
  ];

  static const _types = ['Port', 'Tariff', 'Disaster', 'Geopolitical', 'Logistics'];

  // Hardcoded matching the web UI
  static const _matrix = [
    ['HIGH', 'MEDIUM', 'MEDIUM', 'LOW', 'MEDIUM'],
    ['LOW', 'MEDIUM', null, null, 'HIGH'],
    [null, 'LOW', 'LOW', 'MEDIUM', 'LOW'],
    ['MEDIUM', 'LOW', 'MEDIUM', 'LOW', 'CRITICAL'],
    ['MEDIUM', 'HIGH', 'LOW', 'MEDIUM', 'LOW'],
    ['LOW', 'LOW', null, 'HIGH', 'MEDIUM'],
  ];

  Color _cellColor(String? level) {
    switch (level) {
      case 'CRITICAL':
        return const Color(0xFFFFCDD2);
      case 'HIGH':
        return const Color(0xFFFFE0B2);
      case 'MEDIUM':
        return const Color(0xFFFFF9C4);
      case 'LOW':
        return const Color(0xFFE8F5E9);
      default:
        return const Color(0xFFF5F5F5);
    }
  }

  Color _textColor(String? level) {
    switch (level) {
      case 'CRITICAL':
        return const Color(0xFFB71C1C);
      case 'HIGH':
        return const Color(0xFFE65100);
      case 'MEDIUM':
        return const Color(0xFFF57F17);
      case 'LOW':
        return const Color(0xFF2E7D32);
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                const SizedBox(width: 110),
                ..._types.map((t) => SizedBox(
                      width: 82,
                      child: Text(t,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary)),
                    )),
              ],
            ),
            const SizedBox(height: 8),
            // Data rows
            ..._regions.asMap().entries.map((entry) {
              final row = _matrix[entry.key];
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 110,
                      child: Text(entry.value,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary)),
                    ),
                    ...row.map((level) => Container(
                          width: 82,
                          height: 32,
                          margin: const EdgeInsets.only(right: 4),
                          decoration: BoxDecoration(
                            color: _cellColor(level),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Text(
                              level ?? '—',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: _textColor(level)),
                            ),
                          ),
                        )),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
            // Legend
            Row(
              children: [
                const SizedBox(width: 110),
                _LegendChip('No signal', const Color(0xFFF5F5F5), AppColors.textSecondary),
                _LegendChip('LOW', const Color(0xFFE8F5E9), const Color(0xFF2E7D32)),
                _LegendChip('MEDIUM', const Color(0xFFFFF9C4), const Color(0xFFF57F17)),
                _LegendChip('HIGH', const Color(0xFFFFE0B2), const Color(0xFFE65100)),
                _LegendChip('CRITICAL', const Color(0xFFFFCDD2), const Color(0xFFB71C1C)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const _LegendChip(this.label, this.bg, this.fg);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(fontSize: 9, color: fg, fontWeight: FontWeight.w600)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Risk Leaderboard
// ─────────────────────────────────────────────────────────────────────────────

class _RiskLeaderboard extends StatelessWidget {
  final List<Vendor> vendors;
  const _RiskLeaderboard({required this.vendors});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF8F8F8),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: const [
                SizedBox(width: 28, child: Text('#', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary))),
                Expanded(child: Text('VENDOR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary))),
                SizedBox(width: 70, child: Text('TRUST', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary))),
                SizedBox(width: 60, child: Text('RISK', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary))),
              ],
            ),
          ),
          // Table rows
          ...vendors.asMap().entries.map((entry) {
            final i = entry.key;
            final vendor = entry.value;
            final score = vendor.trustScore?.overallScore ?? 0;
            final riskLabel = score >= 75
                ? 'LOW'
                : score >= 50
                    ? 'MEDIUM'
                    : score >= 25
                        ? 'HIGH'
                        : 'CRITICAL';
            final riskColor = score >= 75
                ? Colors.green
                : score >= 50
                    ? const Color(0xFFF57F17)
                    : score >= 25
                        ? Colors.orange
                        : Colors.red;

            return Column(
              children: [
                const Divider(height: 1, color: Color(0xFFEEEEEE)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 28,
                        child: Text('${i + 1}',
                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                      ),
                      Expanded(
                        child: Text(vendor.legalName,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      ),
                      SizedBox(
                        width: 70,
                        child: Center(
                          child: Text('$score',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: riskColor)),
                        ),
                      ),
                      SizedBox(
                        width: 60,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: riskColor.withAlpha(25),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(riskLabel,
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: riskColor)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Live Disruption Feed
// ─────────────────────────────────────────────────────────────────────────────

class _DisruptionFeed extends StatelessWidget {
  final List<Map<String, dynamic>> events;
  const _DisruptionFeed({required this.events});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Column(
          children: events.asMap().entries.map((entry) {
            final event = entry.value;
            final severity = event['severity'] as String? ?? 'low';
            final color = AppTheme.riskColor(severity);
            return AnimationConfiguration.staggeredList(
              position: entry.key,
              duration: const Duration(milliseconds: 375),
              child: SlideAnimation(
                verticalOffset: 50,
                child: FadeInAnimation(
                  child: Column(
                    children: [
                      if (entry.key > 0)
                        const Divider(height: 1, color: Color(0xFFEEEEEE)),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(top: 4, right: 12),
                              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(event['title'] ?? 'Event',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: AppColors.textPrimary)),
                                  const SizedBox(height: 4),
                                  Text(event['summary'] ?? '',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary)),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: color.withAlpha(25),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(severity.toUpperCase(),
                                        style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            color: color)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.rss_feed, size: 48, color: AppColors.textSecondary.withAlpha(80)),
              const SizedBox(height: 16),
              const Text('No disruption events',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              const Text('Live events from the monitored news corpus will appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}
