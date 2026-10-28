// lib/features/vendors/screens/vendor_detail_screen.dart
//
// Full Vendor Detail screen with 5 tabs matching the website's VendorDetail.tsx:
//   Overview | Verification | Compliance | Risk History | Activity

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_client.dart';
import '../../../core/models/relationship.dart';
import '../../../core/models/vendor.dart';
import '../../../core/providers/demo_mode_provider.dart';
import '../../../core/providers/vendors_provider.dart';
import '../../../core/services/demo_data.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/trust_score_badge.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

String _trustBand(int score) {
  if (score >= 75) return 'Excellent';
  if (score >= 60) return 'Good';
  if (score >= 40) return 'Fair';
  if (score >= 25) return 'At Risk';
  return 'Critical';
}

Color _trustBandColor(int score) {
  if (score >= 75) return const Color(0xFF2E7D32);
  if (score >= 60) return const Color(0xFF558B2F);
  if (score >= 40) return const Color(0xFFF57F17);
  if (score >= 25) return Colors.orange;
  return Colors.red;
}

String _relativeTime(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inDays > 30) return DateFormat('dd MMM yyyy').format(dt);
  if (diff.inDays > 0) return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
  if (diff.inHours > 0) return '${diff.inHours}h ago';
  if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
  return 'Just now';
}

Color _expiryColor(DateTime? expiry) {
  if (expiry == null) return AppColors.textSecondary;
  final days = expiry.difference(DateTime.now()).inDays;
  if (days < 0) return Colors.red;
  if (days < 30) return Colors.red;
  if (days < 60) return Colors.orange;
  if (days < 90) return const Color(0xFFF57F17);
  return const Color(0xFF2E7D32);
}

String _expiryLabel(DateTime? expiry) {
  if (expiry == null) return 'No expiry';
  final days = expiry.difference(DateTime.now()).inDays;
  if (days < 0) return 'EXPIRED ${days.abs()}d ago';
  if (days < 30) return '$days days left';
  if (days < 60) return '$days days left';
  if (days < 90) return '$days days left';
  return 'Valid – ${DateFormat('dd MMM yyyy').format(expiry)}';
}

IconData _kindIcon(VendorEventKind kind) {
  switch (kind) {
    case VendorEventKind.verification:
      return Icons.verified_outlined;
    case VendorEventKind.compliance:
      return Icons.assignment_outlined;
    case VendorEventKind.risk:
      return Icons.warning_amber_outlined;
    case VendorEventKind.trust:
      return Icons.trending_up;
    case VendorEventKind.rfq:
      return Icons.request_quote_outlined;
    case VendorEventKind.document:
      return Icons.description_outlined;
  }
}

Color _kindColor(VendorEventKind kind) {
  switch (kind) {
    case VendorEventKind.verification:
      return AppColors.verified;
    case VendorEventKind.compliance:
      return AppColors.primary;
    case VendorEventKind.risk:
      return Colors.orange;
    case VendorEventKind.trust:
      return const Color(0xFF2E7D32);
    case VendorEventKind.rfq:
      return AppColors.primaryLight;
    case VendorEventKind.document:
      return AppColors.textSecondary;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main Screen
// ─────────────────────────────────────────────────────────────────────────────

class VendorDetailScreen extends ConsumerWidget {
  final String vendorId;
  const VendorDetailScreen({super.key, required this.vendorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDemo = ref.watch(isDemoModeProvider);
    if (isDemo) {
      try {
        final vendor = demoVendors.firstWhere((v) => v.id == vendorId);
        return _VendorDetailView(vendor: vendor);
      } catch (_) {
        return Scaffold(
          appBar: AppBar(title: const Text('Vendor')),
          body: const Center(child: Text('Vendor not found in demo data.')),
        );
      }
    }

    final vendorAsync = ref.watch(vendorDetailProvider(vendorId));
    return vendorAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Loading…')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Vendor')),
        body: Center(
          child: Text('Error: $e', style: const TextStyle(color: AppColors.failed)),
        ),
      ),
      data: (vendor) => _VendorDetailView(vendor: vendor),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Detail View (stateful for tabs, verification and relationships)
// ─────────────────────────────────────────────────────────────────────────────

class _VendorDetailView extends ConsumerStatefulWidget {
  final Vendor vendor;
  const _VendorDetailView({required this.vendor});

  @override
  ConsumerState<_VendorDetailView> createState() => _VendorDetailViewState();
}

class _VendorDetailViewState extends ConsumerState<_VendorDetailView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late Vendor _vendor;
  bool _verifying = false;
  List<SupplierRelationship> _relationships = [];
  List<Map<String, dynamic>> _matchedDisruptions = [];

  static const _tabLabels = [
    'Overview',
    'Verification',
    'Compliance',
    'Risk History',
    'Activity'
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _tabLabels.length, vsync: this);
    _vendor = widget.vendor;
    _loadRelationshipsAndDisruptions();
  }

  Future<void> _loadRelationshipsAndDisruptions() async {
    final isDemo = ref.read(isDemoModeProvider);
    if (isDemo) {
      setState(() {
        _relationships = demoRelationships
            .where((r) => r.vendorAId == _vendor.id || r.vendorBId == _vendor.id)
            .toList();
        _matchedDisruptions = demoIntelligenceEvents.where((e) {
          final aff = e['affectedVendors'] as List<dynamic>? ?? [];
          return aff.any((a) => a['vendorId'] == _vendor.id);
        }).toList();
      });
      return;
    }

    try {
      final relsRaw = await ApiClient.instance.getRelationships(_vendor.id);
      final disruptionsRaw =
          await ApiClient.instance.disruptionEventsForVendor(_vendor.id);
      if (mounted) {
        setState(() {
          _relationships =
              relsRaw.map((j) => SupplierRelationship.fromJson(j)).toList();
          _matchedDisruptions = disruptionsRaw;
        });
      }
    } catch (_) {
      // Ignore network errors in detail background fetch
    }
  }

  Future<void> _triggerSurepassVerification() async {
    if (_verifying) return;
    setState(() => _verifying = true);

    final isDemo = ref.read(isDemoModeProvider);
    if (isDemo) {
      await Future.delayed(const Duration(milliseconds: 1100));

      // Simulate full verification
      final updatedVerifs = [
        VerificationRecord(
          id: 'vr-${_vendor.id}-gstin',
          type: VerificationType.gstin,
          status: VerificationStatus.success,
          createdAt: DateTime.now(),
        ),
        VerificationRecord(
          id: 'vr-${_vendor.id}-pan',
          type: VerificationType.pan,
          status: VerificationStatus.success,
          createdAt: DateTime.now(),
        ),
        VerificationRecord(
          id: 'vr-${_vendor.id}-udyam',
          type: VerificationType.udyam,
          status: VerificationStatus.success,
          createdAt: DateTime.now(),
        ),
        if (_vendor.cin != null)
          VerificationRecord(
            id: 'vr-${_vendor.id}-cin',
            type: VerificationType.cin,
            status: VerificationStatus.success,
            createdAt: DateTime.now(),
          ),
      ];

      final currentOverall = _vendor.trustScore?.overallScore ?? 50;
      final newScore = min(98, max(currentOverall, currentOverall + 12));
      final newTs = TrustScore(
        overallScore: newScore,
        verificationCompleteness: 40,
        certificationFreshness: _vendor.trustScore?.certificationFreshness ?? 32,
        accountAgeActivity: _vendor.trustScore?.accountAgeActivity ?? 12,
        manualBuyerFlag: _vendor.trustScore?.manualBuyerFlag ?? 6,
        riskLevel: newScore >= 75 ? RiskLevel.low : RiskLevel.medium,
      );

      final newEvent = VendorEvent(
        id: 'ev-kyb-${DateTime.now().millisecondsSinceEpoch}',
        kind: VendorEventKind.verification,
        title: 'Surepass KYB Verification Succeeded',
        detail:
            'Real-time automated check via GSTN & Income Tax API confirmed valid.',
        at: DateTime.now(),
      );

      if (mounted) {
        setState(() {
          _vendor = Vendor(
            id: _vendor.id,
            legalName: _vendor.legalName,
            tradeName: _vendor.tradeName,
            email: _vendor.email,
            phone: _vendor.phone,
            pan: _vendor.pan,
            gstin: _vendor.gstin,
            cin: _vendor.cin,
            udyamNumber: _vendor.udyamNumber,
            msmeCategory: _vendor.msmeCategory,
            city: _vendor.city,
            state: _vendor.state,
            categories: _vendor.categories,
            contactName: _vendor.contactName,
            contactRole: _vendor.contactRole,
            status: VendorStatus.verified,
            buyerFlagNote: _vendor.buyerFlagNote,
            onboardedAt: _vendor.onboardedAt,
            trustScore: newTs,
            trustHistory: [
              ..._vendor.trustHistory,
              TrustHistoryPoint(score: newScore, recordedAt: DateTime.now()),
            ],
            verifications: updatedVerifs,
            documents: _vendor.documents,
            events: [newEvent, ..._vendor.events],
          );
          _verifying = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.verified,
            content: Text(
              'Surepass KYB check completed: ${_vendor.legalName} verified. Trust Score updated to $newScore.',
            ),
          ),
        );
      }
      return;
    }

    try {
      final res =
          await ApiClient.instance.triggerVendorVerification(_vendor.id);
      if (mounted) {
        setState(() {
          _vendor = Vendor.fromJson(res);
          _verifying = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.verified,
            content: Text('Surepass verification pipeline completed successfully.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _verifying = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.failed,
            content: Text('Verification failed: $e'),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final v = _vendor;
    final riskLevel = v.trustScore?.riskLevel ?? RiskLevel.medium;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            floating: false,
            elevation: 0,
            backgroundColor: AppColors.primary,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding:
                  const EdgeInsets.only(left: 52, bottom: 58, right: 16),
              title: Text(
                v.displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryLight],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  Positioned(
                    right: -20,
                    bottom: -20,
                    child: Icon(Icons.business,
                        size: 120, color: Colors.white.withAlpha(20)),
                  ),
                  // Status & Risk badges
                  Positioned(
                    left: 16,
                    bottom: 58,
                    child: Row(
                      children: [
                        _HeaderChip(
                          v.status.label,
                          v.status == VendorStatus.verified
                              ? AppColors.verified
                              : v.status == VendorStatus.flagged
                                  ? Colors.red
                                  : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        _HeaderChip(
                          riskLevel.label,
                          AppTheme.riskColor(riskLevel.label),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            bottom: TabBar(
              controller: _tabs,
              isScrollable: true,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              labelStyle:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              tabs: _tabLabels.map((l) => Tab(text: l)).toList(),
            ),
          ),
        ],
        body: Column(
          children: [
            // Flagged banner
            if (v.status == VendorStatus.flagged && v.buyerFlagNote != null)
              Container(
                width: double.infinity,
                color: Colors.red.shade50,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.flag, color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Vendor Flagged',
                              style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13)),
                          Text(v.buyerFlagNote!,
                              style: TextStyle(
                                  color: Colors.red.shade700, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Relationship Warning Banner (Cross-Entity Detection)
            if (_relationships.isNotEmpty)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFFD54F)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.hub_outlined,
                        color: Color(0xFFE65100), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Potential Relationship Detected (${_relationships.length})',
                            style: const TextStyle(
                              color: Color(0xFFE65100),
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _relationships.map((r) {
                              final otherName = r.vendorAId == _vendor.id
                                  ? (r.vendorBName ?? r.vendorBId)
                                  : (r.vendorAName ?? r.vendorAId);
                              return '${r.type.label} with $otherName (${r.value})';
                            }).join(' · '),
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _OverviewTab(
                    vendor: v,
                    relationships: _relationships,
                  ),
                  _VerificationTab(
                    vendor: v,
                    verifying: _verifying,
                    onVerify: _triggerSurepassVerification,
                  ),
                  _ComplianceTab(vendor: v),
                  _RiskHistoryTab(
                    vendor: v,
                    disruptions: _matchedDisruptions,
                  ),
                  _ActivityTab(vendor: v),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  final String label;
  final Color color;
  const _HeaderChip(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(60),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(120)),
      ),
      child: Text(label,
          style: const TextStyle(
              color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1: Overview
// ─────────────────────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final Vendor vendor;
  final List<SupplierRelationship> relationships;
  const _OverviewTab({required this.vendor, required this.relationships});

  @override
  Widget build(BuildContext context) {
    final ts = vendor.trustScore;
    final score = ts?.overallScore ?? 0;
    final band = _trustBand(score);
    final bandColor = _trustBandColor(score);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Trust score card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Trust Score',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.textSecondary)),
                        Text('$score',
                            style: TextStyle(
                                fontSize: 52,
                                fontWeight: FontWeight.w700,
                                color: bandColor,
                                height: 1.1)),
                        Text(band,
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: bandColor)),
                      ],
                    ),
                    const Spacer(),
                    TrustScorePill(score: score),
                  ],
                ),
                if (ts != null) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  _ScoreRow('Verification Completeness',
                      ts.verificationCompleteness, 40),
                  _ScoreRow(
                      'Certification Freshness', ts.certificationFreshness, 35),
                  _ScoreRow('Account Age & Activity', ts.accountAgeActivity, 15),
                  _ScoreRow('Manual Buyer Flag', ts.manualBuyerFlag, 10),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Supplier Relationships card (Cross-entity graph detection)
        if (relationships.isNotEmpty) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.hub_outlined,
                          size: 18, color: Color(0xFFE65100)),
                      const SizedBox(width: 8),
                      const Text(
                        'Supplier Relationships',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Cross-entity ties detected via shared directors, accounts or addresses.',
                    style:
                        TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  ...relationships.map((rel) {
                    final isA = rel.vendorAId == vendor.id;
                    final otherName =
                        isA ? (rel.vendorBName ?? rel.vendorBId) : (rel.vendorAName ?? rel.vendorAId);
                    final otherId = isA ? rel.vendorBId : rel.vendorAId;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBFBFB),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFEEEEEE)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3E0),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              rel.type.label,
                              style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFE65100)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  otherName,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  rel.value,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.arrow_forward_ios,
                                size: 14, color: AppColors.textSecondary),
                            onPressed: () => context.push('/vendor/$otherId'),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // KYB Identifiers
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('KYB Identifiers',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 12),
                _KybRow('GSTIN', vendor.gstin),
                _KybRow('PAN', vendor.pan),
                _KybRow('CIN', vendor.cin),
                _KybRow('Udyam No.', vendor.udyamNumber),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Contact & Location
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Contact & Location',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 12),
                _InfoRow(
                    Icons.person_outline,
                    vendor.contactName.isEmpty ? '—' : vendor.contactName,
                    vendor.contactRole.isEmpty ? '' : vendor.contactRole),
                const SizedBox(height: 8),
                _InfoRow(Icons.email_outlined, vendor.email, ''),
                const SizedBox(height: 8),
                _InfoRow(Icons.phone_outlined, vendor.phone, ''),
                const SizedBox(height: 8),
                _InfoRow(
                    Icons.location_on_outlined,
                    '${vendor.city}, ${vendor.state}',
                    vendor.msmeCategory.label),
                if (vendor.categories.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: vendor.categories
                        .map((c) => Chip(
                              label: Text(c,
                                  style: const TextStyle(fontSize: 11)),
                              padding: EdgeInsets.zero,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final String label;
  final int value;
  final int max;
  const _ScoreRow(this.label, this.value, this.max);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ),
              Text('$value / $max',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: max > 0 ? value / max : 0,
              minHeight: 6,
              backgroundColor: const Color(0xFFE8E8E8),
              valueColor: AlwaysStoppedAnimation<Color>(
                  _trustBandColor(((value / max) * 100).round())),
            ),
          ),
        ],
      ),
    );
  }
}

class _KybRow extends StatelessWidget {
  final String label;
  final String? value;
  const _KybRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(
              hasValue ? value! : 'Not provided',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                fontFamily: hasValue ? 'monospace' : null,
                color:
                    hasValue ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
          ),
          Icon(
            hasValue ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: hasValue ? AppColors.verified : AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String primary;
  final String secondary;
  const _InfoRow(this.icon, this.primary, this.secondary);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(primary,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500)),
              if (secondary.isNotEmpty)
                Text(secondary,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2: Verification (with Surepass KYB action)
// ─────────────────────────────────────────────────────────────────────────────

class _VerificationTab extends StatelessWidget {
  final Vendor vendor;
  final bool verifying;
  final VoidCallback onVerify;

  const _VerificationTab({
    required this.vendor,
    required this.verifying,
    required this.onVerify,
  });

  @override
  Widget build(BuildContext context) {
    final verifications = vendor.verifications;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Surepass KYB Trigger Card
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFDDE3EA)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(20),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.shield_outlined,
                          color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('KYB Verification Engine',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: AppColors.textPrimary)),
                          Text(
                            'Powered by Surepass (GSTIN · PAN · Udyam · CIN)',
                            style: TextStyle(
                                fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Runs automated queries against the GST Network, Income Tax registry and MCA corporate database to calculate the verification completeness score.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: verifying ? null : onVerify,
                    icon: verifying
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.verified_user, size: 16),
                    label: Text(
                      verifying
                          ? 'Verifying with Surepass…'
                          : 'Re-verify with Surepass',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        if (verifications.isEmpty)
          const _EmptyState(Icons.verified_outlined, 'No verifications',
              'Verification records will appear after KYB checks are run.')
        else
          ...verifications.map((vr) {
            final (icon, color) = switch (vr.status) {
              VerificationStatus.success => (
                Icons.check_circle,
                AppColors.verified
              ),
              VerificationStatus.failed => (Icons.cancel, Colors.red),
              VerificationStatus.manualReview => (
                Icons.visibility,
                Colors.blue
              ),
              _ => (Icons.pending, Colors.orange),
            };
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(icon, color: color, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(vr.type.label,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 14)),
                          const SizedBox(height: 2),
                          Text(
                            'Checked ${DateFormat('dd MMM yyyy').format(vr.createdAt)}',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withAlpha(20),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: color.withAlpha(60)),
                      ),
                      child: Text(vr.status.label,
                          style: TextStyle(
                              color: color,
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            );
          }),
        const SizedBox(height: 80),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 3: Compliance
// ─────────────────────────────────────────────────────────────────────────────

class _ComplianceTab extends StatelessWidget {
  final Vendor vendor;
  const _ComplianceTab({required this.vendor});

  @override
  Widget build(BuildContext context) {
    final docs = vendor.documents;
    if (docs.isEmpty) {
      return const _EmptyState(Icons.assignment_outlined, 'No documents',
          'Compliance documents uploaded by the vendor will appear here.');
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: docs.length,
      separatorBuilder: (_, index) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final doc = docs[i];
        final expiryColor = _expiryColor(doc.expirationDate);
        final expiryLabel = _expiryLabel(doc.expirationDate);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.description_outlined,
                        size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(doc.type,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: expiryColor.withAlpha(20),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: expiryColor.withAlpha(60)),
                      ),
                      child: Text(expiryLabel,
                          style: TextStyle(
                              color: expiryColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                if (doc.certificateNumber != null) ...[
                  const SizedBox(height: 6),
                  Text('No: ${doc.certificateNumber}',
                      style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: AppColors.textSecondary)),
                ],
                if (doc.issuingAuthority != null) ...[
                  const SizedBox(height: 2),
                  Text('Issued by: ${doc.issuingAuthority}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Uploaded ${DateFormat('dd MMM yyyy').format(doc.uploadedAt)}',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                    if (doc.confidence != null) ...[
                      const Spacer(),
                      Text(
                        'OCR ${(doc.confidence! * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 4: Risk History (sparkline + matched disruption events)
// ─────────────────────────────────────────────────────────────────────────────

class _RiskHistoryTab extends StatelessWidget {
  final Vendor vendor;
  final List<Map<String, dynamic>> disruptions;
  const _RiskHistoryTab({required this.vendor, required this.disruptions});

  @override
  Widget build(BuildContext context) {
    final history = vendor.trustHistory;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Matched Disruption Events card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.radar_outlined,
                        size: 18, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text(
                      'Matched Disruption Radar Events',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Events from the supplier intelligence feed linked to this vendor.',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                if (disruptions.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F9F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'No disruption events currently matched to this vendor.',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  )
                else
                  ...disruptions.map((e) {
                    final sev = e['severity']?.toString() ?? 'MEDIUM';
                    final color = AppTheme.riskColor(sev);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withAlpha(15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: color.withAlpha(60)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  sev.toUpperCase(),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  e['title'] ?? 'Disruption Event',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            e['summary'] ?? '',
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Trust score over time chart
        if (history.isNotEmpty) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Trust Score Over Time',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text(
                    '${history.length} data points · '
                    '${history.first.score} → ${history.last.score}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 160,
                    child: CustomPaint(
                      painter: _SparklinePainter(history),
                      child: Container(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // X labels (first and last date)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('dd MMM').format(history.first.recordedAt),
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary),
                      ),
                      Text(
                        DateFormat('dd MMM').format(history.last.recordedAt),
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Data points list
          Card(
            child: Column(
              children: history.reversed.toList().asMap().entries.map((e) {
                final point = e.value;
                final prev = e.key < history.length - 1
                    ? history.reversed.toList()[e.key + 1]
                    : null;
                final delta = prev != null ? point.score - prev.score : 0;
                return Column(
                  children: [
                    if (e.key > 0)
                      const Divider(height: 1, color: Color(0xFFEEEEEE)),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      child: Row(
                        children: [
                          Text(
                            DateFormat('dd MMM yyyy').format(point.recordedAt),
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.textSecondary),
                          ),
                          const Spacer(),
                          Text(
                            '${point.score}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _trustBandColor(point.score),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (delta != 0)
                            Icon(
                              delta > 0
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              size: 14,
                              color: delta > 0
                                  ? AppColors.verified
                                  : Colors.red,
                            ),
                          if (delta != 0)
                            Text(
                              '${delta.abs()}',
                              style: TextStyle(
                                fontSize: 12,
                                color: delta > 0
                                    ? AppColors.verified
                                    : Colors.red,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
        const SizedBox(height: 80),
      ],
    );
  }
}

// Custom sparkline painter
class _SparklinePainter extends CustomPainter {
  final List<TrustHistoryPoint> points;
  _SparklinePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final scores = points.map((p) => p.score.toDouble()).toList();
    final minScore =
        scores.reduce((a, b) => a < b ? a : b).clamp(0, 100).toDouble();
    final maxScore =
        scores.reduce((a, b) => a > b ? a : b).clamp(0, 100).toDouble();
    final range = (maxScore - minScore).clamp(10, 100).toDouble();

    // Grid lines
    final gridPaint = Paint()
      ..color = const Color(0xFFEEEEEE)
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Fill
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.primary.withAlpha(60),
          AppColors.primary.withAlpha(0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final fillPath = Path();

    for (var i = 0; i < points.length; i++) {
      final x = size.width * i / (points.length - 1);
      final y = size.height -
          ((scores[i] - minScore) / range * (size.height - 20)) -
          10;
      if (i == 0) {
        fillPath.moveTo(x, y);
      } else {
        fillPath.lineTo(x, y);
      }
    }
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);

    // Line
    final linePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final linePath = Path();
    for (var i = 0; i < points.length; i++) {
      final x = size.width * i / (points.length - 1);
      final y = size.height -
          ((scores[i] - minScore) / range * (size.height - 20)) -
          10;
      if (i == 0) {
        linePath.moveTo(x, y);
      } else {
        linePath.lineTo(x, y);
      }
    }
    canvas.drawPath(linePath, linePaint);

    // Dots
    final dotPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;
    for (var i = 0; i < points.length; i++) {
      final x = size.width * i / (points.length - 1);
      final y = size.height -
          ((scores[i] - minScore) / range * (size.height - 20)) -
          10;
      canvas.drawCircle(Offset(x, y), 3.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 5: Activity
// ─────────────────────────────────────────────────────────────────────────────

class _ActivityTab extends StatelessWidget {
  final Vendor vendor;
  const _ActivityTab({required this.vendor});

  @override
  Widget build(BuildContext context) {
    final events = vendor.events;
    if (events.isEmpty) {
      return const _EmptyState(Icons.history, 'No activity recorded',
          'Verification events, score changes and RFQ activity will appear here.');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, i) {
        final ev = events[i];
        final color = _kindColor(ev.kind);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_kindIcon(ev.kind), size: 16, color: color),
                ),
                if (i < events.length - 1)
                  Container(
                    width: 2,
                    height: 40,
                    color: const Color(0xFFEEEEEE),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding:
                    EdgeInsets.only(bottom: i < events.length - 1 ? 0 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(ev.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13)),
                        ),
                        Text(_relativeTime(ev.at),
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(ev.detail,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty State
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyState(this.icon, this.title, this.subtitle);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.textSecondary.withAlpha(80)),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
