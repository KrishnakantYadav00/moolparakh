// lib/features/trust_score/screens/trust_score_screen.dart
//
// Trust score drilldown — shows the full score breakdown for a vendor.
//
// Trust score formula (PRD §15.4 / frontend/src/utils/trustScore.ts):
//   Verification Completeness  /40 — all 4 government IDs verified
//   Certification Freshness    /35 — documents not expired / near expiry
//   Account Age & Activity     /15 — tenure + recent event activity
//   Manual Buyer Flag          /10 — buyer can subtract points for concerns
//   ─────────────────────────────
//   Overall                   /100
//
// Also shows the 30-day trust history sparkline using fl_chart.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/models/vendor.dart';
import '../../../core/providers/vendors_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/trust_score_badge.dart';
import '../../../shared/widgets/status_chip.dart';

class TrustScoreScreen extends ConsumerWidget {
  final String vendorId;
  const TrustScoreScreen({super.key, required this.vendorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vendorAsync = ref.watch(vendorDetailProvider(vendorId));

    return Scaffold(
      appBar: AppBar(title: const Text('Trust Score')),
      body: vendorAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (vendor) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _ScoreSummaryCard(vendor: vendor),
            const SizedBox(height: 16),
            if (vendor.trustHistory.isNotEmpty)
              _SparklineCard(history: vendor.trustHistory),
            const SizedBox(height: 16),
            _ComponentBreakdownCard(ts: vendor.trustScore),
            const SizedBox(height: 16),
            _Section43bCard(vendor: vendor),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Score summary card
// ──────────────────────────────────────────────────────────────────────────────

class _ScoreSummaryCard extends StatelessWidget {
  final Vendor vendor;
  const _ScoreSummaryCard({required this.vendor});

  @override
  Widget build(BuildContext context) {
    final ts = vendor.trustScore;
    final score = ts?.overallScore ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              vendor.displayName,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Hero(
              tag: 'trust-badge-${vendor.id}',
              child: Material(
                color: Colors.transparent,
                child: TrustScoreBadge(score: score, size: 100, strokeWidth: 9),
              ),
            ),
            const SizedBox(height: 16),
            if (ts != null) ...[
              StatusChip.riskLevel(ts.riskLevel.name.toUpperCase()),
              const SizedBox(height: 8),
              Text(
                'Last calculated: ${_timeAgo(vendor.trustHistory.firstOrNull?.recordedAt ?? DateTime.now())}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 30-day sparkline
// ──────────────────────────────────────────────────────────────────────────────

class _SparklineCard extends StatelessWidget {
  final List<TrustHistoryPoint> history;
  const _SparklineCard({required this.history});

  @override
  Widget build(BuildContext context) {
    // Show last 30 points max
    final points = history.length > 30
        ? history.sublist(history.length - 30)
        : history;

    final spots = List.generate(
      points.length,
      (i) => FlSpot(i.toDouble(), points[i].score.toDouble()),
    );

    final latest = points.last.score;
    final color = AppTheme.trustColor(latest);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '30-Day Trust History',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: 100,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 25,
                    getDrawingHorizontalLine: (_) =>
                        FlLine(color: AppColors.divider, strokeWidth: 1),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 25,
                        reservedSize: 30,
                        getTitlesWidget: (v, _) => Text(
                          '${v.toInt()}',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(fontSize: 10),
                        ),
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: color,
                      barWidth: 2.5,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: color.withAlpha(30),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('dd MMM').format(points.first.recordedAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text('Today', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Component breakdown card
// ──────────────────────────────────────────────────────────────────────────────

class _ComponentBreakdownCard extends StatelessWidget {
  final TrustScore? ts;
  const _ComponentBreakdownCard({this.ts});

  @override
  Widget build(BuildContext context) {
    if (ts == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Score not yet computed.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    final rows = [
      _ScoreComponent(
        label: 'Verification Completeness',
        earned: ts!.verificationCompleteness,
        max: 40,
        note: 'All 4 government IDs verified (PAN, GSTIN, Udyam, CIN)',
      ),
      _ScoreComponent(
        label: 'Certification Freshness',
        earned: ts!.certificationFreshness,
        max: 35,
        note: 'Certificates valid and not expiring within 90 days',
      ),
      _ScoreComponent(
        label: 'Account Age & Activity',
        earned: ts!.accountAgeActivity,
        max: 15,
        note: 'Tenure on platform + recent document/event activity',
      ),
      _ScoreComponent(
        label: 'Buyer Flag Adjustment',
        earned: ts!.manualBuyerFlag,
        max: 10,
        note: 'Buyer-applied adjustment for observed concerns',
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Score Breakdown',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 16),
            ...rows.map((r) => _ComponentRow(component: r)),
          ],
        ),
      ),
    );
  }
}

class _ScoreComponent {
  final String label;
  final int earned;
  final int max;
  final String note;
  const _ScoreComponent({
    required this.label,
    required this.earned,
    required this.max,
    required this.note,
  });
}

class _ComponentRow extends StatelessWidget {
  final _ScoreComponent component;
  const _ComponentRow({required this.component});

  @override
  Widget build(BuildContext context) {
    final pct = component.earned / component.max;
    final color = AppTheme.trustColor((pct * 100).round());

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  component.label,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Text(
                '${component.earned} / ${component.max}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 4),
          Text(component.note, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Section 43B(h) compliance card
// ──────────────────────────────────────────────────────────────────────────────

class _Section43bCard extends StatelessWidget {
  final Vendor vendor;
  const _Section43bCard({required this.vendor});

  @override
  Widget build(BuildContext context) {
    // Section 43B(h) risk: if vendor has MSME registration and it's
    // not verified, the buyer risks a 45-day payment compliance issue.
    final udyamVerified = vendor.verifications.any(
      (v) =>
          v.type == VerificationType.udyam &&
          v.status == VerificationStatus.success,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  udyamVerified ? Icons.gavel : Icons.warning_amber_outlined,
                  size: 18,
                  color: udyamVerified ? AppColors.verified : AppColors.failed,
                ),
                const SizedBox(width: 8),
                Text(
                  'Section 43B(h) Compliance',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              udyamVerified
                  ? '✅ Udyam registration verified. Buyer must pay within 45 days '
                        'to avoid income-tax disallowance under Section 43B(h).'
                  : '⚠️ Udyam registration not verified. Buyer cannot confirm '
                        'MSME status — Section 43B(h) exposure is unquantifiable.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Finance Act 2023, Section 43B(h): payments to MSME suppliers '
              'must be made within 45 days (15 days if no written agreement). '
              'Late payment is disallowed as a business expense.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
