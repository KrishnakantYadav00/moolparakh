// lib/features/dashboard/screens/dashboard_screen.dart
//
// Supplier dashboard — the first tab the supplier sees after login.
//
// Shows:
//   1. Trust score summary card (circular gauge + band label)
//   2. Verification checklist (PAN / GSTIN / Udyam / CIN) 
//   3. Compliance alert (any document expiring within 90 days)
//   4. Open RFQs summary (count + quick-link)
//   5. Recent activity feed (last 5 vendor events)
//
// PRD §9.1.7 — "Android without a stated reason: suppliers receive RFQ
//   time-sensitive alerts while at trade fairs or on factory floors — they
//   cannot sit at a desktop portal."

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/models/vendor.dart';
import '../../../core/providers/vendors_provider.dart';
import '../../../core/providers/rfq_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/trust_score_badge.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../auth/screens/login_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vendorId = ref.watch(currentVendorIdProvider);

    if (vendorId == null) {
      return const Center(child: Text('Not logged in'));
    }

    final vendorAsync = ref.watch(vendorDetailProvider(vendorId));
    final openRfqsAsync = ref.watch(openRfqsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('MoolParakh'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(vendorDetailProvider(vendorId).notifier).refresh();
              ref.read(rfqListProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: vendorAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(message: e.toString()),
        data: (vendor) => RefreshIndicator(
          onRefresh: () async {
            ref.read(vendorDetailProvider(vendorId).notifier).refresh();
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _TrustSummaryCard(vendor: vendor),
              const SizedBox(height: 16),
              _VerificationCard(vendor: vendor),
              const SizedBox(height: 16),
              _ComplianceAlertCard(vendor: vendor),
              const SizedBox(height: 16),
              openRfqsAsync.when(
                loading: () => const _SectionShimmer(label: 'Open RFQs'),
                error: (_, __) => const SizedBox.shrink(),
                data: (rfqs) => _OpenRfqSummaryCard(count: rfqs.length),
              ),
              const SizedBox(height: 16),
              _ActivityFeedCard(events: vendor.events),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Trust summary card
// ──────────────────────────────────────────────────────────────────────────────

class _TrustSummaryCard extends StatelessWidget {
  final Vendor vendor;
  const _TrustSummaryCard({required this.vendor});

  @override
  Widget build(BuildContext context) {
    final ts = vendor.trustScore;
    final score = ts?.overallScore ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            TrustScoreBadge(score: score, size: 80, strokeWidth: 7),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vendor.displayName,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  StatusChip.vendorStatus(vendor.status.name.toUpperCase()),
                  const SizedBox(height: 8),
                  if (ts != null) ...[
                    _ScoreRow(
                        'Verification', ts.verificationCompleteness, 40),
                    _ScoreRow(
                        'Cert Freshness', ts.certificationFreshness, 35),
                    _ScoreRow(
                        'Account Age', ts.accountAgeActivity, 15),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final String label;
  final int earned;
  final int max;
  const _ScoreRow(this.label, this.earned, this.max);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: Theme.of(context).textTheme.bodySmall),
          ),
          Text(
            '$earned/$max',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.trustColor(
                      (earned / max * 100).round()),
                ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Verification card
// ──────────────────────────────────────────────────────────────────────────────

class _VerificationCard extends StatelessWidget {
  final Vendor vendor;
  const _VerificationCard({required this.vendor});

  @override
  Widget build(BuildContext context) {
    final checks = {
      'PAN': _statusFor('PAN', vendor.verifications),
      'GSTIN': _statusFor('GSTIN', vendor.verifications),
      'Udyam': _statusFor('UDYAM', vendor.verifications),
      'CIN': _statusFor('CIN', vendor.verifications),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.fact_check_outlined,
                    size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text('Verification Checks',
                    style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: checks.entries.map((e) {
                return _VerifItem(label: e.key, status: e.value);
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  String _statusFor(String type, List<VerificationRecord> records) {
    final match = records.where(
      (r) => r.type.name.toUpperCase() == type.toUpperCase(),
    );
    if (match.isEmpty) return 'PENDING';
    return match.first.status.name.toUpperCase();
  }
}

class _VerifItem extends StatelessWidget {
  final String label;
  final String status;
  const _VerifItem({required this.label, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.verificationColor(status);
    final icon = status == 'SUCCESS'
        ? Icons.check_circle
        : status == 'FAILED'
            ? Icons.cancel
            : Icons.hourglass_empty;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w500, color: color)),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Compliance alert card
// ──────────────────────────────────────────────────────────────────────────────

class _ComplianceAlertCard extends StatelessWidget {
  final Vendor vendor;
  const _ComplianceAlertCard({required this.vendor});

  @override
  Widget build(BuildContext context) {
    final expiring = vendor.documents
        .where((d) => d.isExpiringSoon && !d.isExpired)
        .toList();
    final expired =
        vendor.documents.where((d) => d.isExpired).toList();

    if (expiring.isEmpty && expired.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.check_circle,
                  color: AppColors.verified, size: 20),
              const SizedBox(width: 8),
              Text('All certificates up to date',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.verified)),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  expired.isNotEmpty
                      ? Icons.error_outline
                      : Icons.warning_amber_outlined,
                  color: expired.isNotEmpty
                      ? AppColors.failed
                      : AppColors.pending,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  expired.isNotEmpty
                      ? '${expired.length} Expired'
                      : '${expiring.length} Expiring Soon',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: expired.isNotEmpty
                            ? AppColors.failed
                            : AppColors.pending,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...[ ...expired, ...expiring].take(3).map(
              (d) {
                final exp = d.expirationDate;
                final days = exp != null
                    ? exp.difference(DateTime.now()).inDays
                    : null;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(d.type,
                            style: const TextStyle(fontSize: 13)),
                      ),
                      Text(
                        days == null
                            ? '—'
                            : days < 0
                                ? 'Expired ${days.abs()}d ago'
                                : 'In ${days}d',
                        style: TextStyle(
                          fontSize: 12,
                          color: d.isExpired
                              ? AppColors.failed
                              : AppColors.pending,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Open RFQ summary card
// ──────────────────────────────────────────────────────────────────────────────

class _OpenRfqSummaryCard extends StatelessWidget {
  final int count;
  const _OpenRfqSummaryCard({required this.count});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.go('/home/rfq'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.request_quote,
                    color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      count == 0
                          ? 'No open RFQs'
                          : '$count Open RFQ${count == 1 ? '' : 's'}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      count == 0
                          ? 'Check back later for new procurement requests'
                          : 'Tap to review and submit bids',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (count > 0)
                const Icon(Icons.chevron_right,
                    color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Activity feed card
// ──────────────────────────────────────────────────────────────────────────────

class _ActivityFeedCard extends StatelessWidget {
  final List<VendorEvent> events;
  const _ActivityFeedCard({required this.events});

  @override
  Widget build(BuildContext context) {
    final recent = events.take(5).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.timeline,
                    size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text('Recent Activity',
                    style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 12),
            if (recent.isEmpty)
              Text('No activity yet.',
                  style: Theme.of(context).textTheme.bodySmall)
            else
              ...recent.map((e) => _EventTile(event: e)),
          ],
        ),
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  final VendorEvent event;
  const _EventTile({required this.event});

  IconData get _icon {
    switch (event.kind) {
      case VendorEventKind.verification:
        return Icons.verified_outlined;
      case VendorEventKind.compliance:
        return Icons.assignment_turned_in_outlined;
      case VendorEventKind.risk:
        return Icons.warning_amber_outlined;
      case VendorEventKind.trust:
        return Icons.star_outline;
      case VendorEventKind.rfq:
        return Icons.request_quote_outlined;
      case VendorEventKind.document:
        return Icons.description_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.title,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500)),
                Text(event.detail,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            DateFormat('dd MMM').format(event.at),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Helpers
// ──────────────────────────────────────────────────────────────────────────────

class _SectionShimmer extends StatelessWidget {
  final String label;
  const _SectionShimmer({required this.label});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_outlined,
                size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text('Could not load data',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(message,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
