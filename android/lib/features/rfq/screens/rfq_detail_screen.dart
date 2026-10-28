// lib/features/rfq/screens/rfq_detail_screen.dart
//
// RFQ detail + bid submission screen.
//
// Shows:
//   - RFQ spec (item, quantity, delivery requirements)
//   - Current bid rankings (BidEvaluator — PRD §15.4)
//   - Supplier's bid submission form
//
// Bid evaluation formula is computed client-side so the slider updates
// are instant (no API call on slider move) — PRD §15.4:
//   "The client-side recomputation uses the already-loaded criterion scores."

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../../core/api/api_client.dart';
import '../../../core/models/rfq.dart';
import '../../../core/providers/rfq_provider.dart';
import '../../../core/providers/vendors_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../../shared/widgets/trust_score_badge.dart';
import '../../auth/screens/login_screen.dart';

final _currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

class RfqDetailScreen extends ConsumerStatefulWidget {
  final String rfqId;
  const RfqDetailScreen({super.key, required this.rfqId});

  @override
  ConsumerState<RfqDetailScreen> createState() => _RfqDetailScreenState();
}

class _RfqDetailScreenState extends ConsumerState<RfqDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _priceCtrl = TextEditingController();
  final _daysCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _submitting = false;
  String? _submitError;
  bool _submitted = false;

  @override
  void dispose() {
    _priceCtrl.dispose();
    _daysCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitBid(Rfq rfq) async {
    if (!_formKey.currentState!.validate()) return;

    final vendorId = ref.read(currentVendorIdProvider);
    if (vendorId == null) return;

    final vendorAsync = ref.read(vendorDetailProvider(vendorId));
    final trustScore = vendorAsync.valueOrNull?.trustScore?.overallScore ?? 0;

    setState(() {
      _submitting = true;
      _submitError = null;
    });

    try {
      await ApiClient.instance.submitBid(
        rfq.id,
        vendorId: vendorId,
        pricePerUnit: double.parse(_priceCtrl.text.trim()),
        deliveryDays: int.parse(_daysCtrl.text.trim()),
        trustScoreAtBid: trustScore,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );

      // Refresh RFQ to show new bid rankings
      ref.read(rfqDetailProvider(rfq.id).notifier).refresh();

      setState(() {
        _submitted = true;
        _submitting = false;
      });
    } catch (e) {
      setState(() {
        _submitError = e.toString();
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final rfqAsync = ref.watch(rfqDetailProvider(widget.rfqId));
    final weightsState = ref.watch(bidWeightsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: rfqAsync.when(
        loading: () => const Scaffold(body: _RfqDetailShimmer()),
        error: (e, _) => Scaffold(
          appBar: AppBar(title: const Text('RFQ Detail')),
          body: Center(
            child: Text(
              'Error: $e',
              style: const TextStyle(color: AppColors.failed),
            ),
          ),
        ),
        data: (rfq) => CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 180.0,
              floating: false,
              pinned: true,
              elevation: 0,
              backgroundColor: AppColors.primary,
              iconTheme: const IconThemeData(color: Colors.white),
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(
                  left: 48,
                  bottom: 16,
                  right: 16,
                ),
                title: Text(
                  rfq.reference,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
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
                      right: -30,
                      bottom: -30,
                      child: Icon(
                        Icons.request_quote_rounded,
                        size: 150,
                        color: Colors.white.withAlpha(20),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverPadding(
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
                        Hero(
                          tag: 'rfq-card-${rfq.id}',
                          child: Material(
                            color: Colors.transparent,
                            child: _RfqHeaderCard(rfq: rfq),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _SpecCard(rfq: rfq),
                        const SizedBox(height: 16),

                        // Show bid rankings only if there are bids
                        if (rfq.bids.isNotEmpty) ...[
                          _BidRankingCard(rfq: rfq, weights: weightsState),
                          const SizedBox(height: 16),
                        ],

                        // Bid form — only for open RFQs
                        if (rfq.status.isOpen && !rfq.isClosed)
                          _submitted
                              ? _BidSubmittedBanner()
                              : _BidForm(
                                  rfq: rfq,
                                  formKey: _formKey,
                                  priceCtrl: _priceCtrl,
                                  daysCtrl: _daysCtrl,
                                  notesCtrl: _notesCtrl,
                                  submitting: _submitting,
                                  error: _submitError,
                                  onSubmit: () => _submitBid(rfq),
                                ),

                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
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

class _RfqDetailShimmer extends StatelessWidget {
  const _RfqDetailShimmer();

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
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Shimmer.fromColors(
          baseColor: AppColors.shimmer,
          highlightColor: AppColors.shimmerHighlight,
          child: Card(
            child: Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// RFQ header card
// ──────────────────────────────────────────────────────────────────────────────

class _RfqHeaderCard extends StatelessWidget {
  final Rfq rfq;
  const _RfqHeaderCard({required this.rfq});

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
                Expanded(
                  child: Text(
                    rfq.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                StatusChip(
                  label: rfq.status.label,
                  color: rfq.status.isOpen
                      ? AppColors.verified
                      : AppColors.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              rfq.reference,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.schedule_outlined,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  rfq.isClosed
                      ? 'Closed'
                      : 'Closes ${DateFormat('dd MMM yyyy HH:mm').format(rfq.closesAt)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Spec card
// ──────────────────────────────────────────────────────────────────────────────

class _SpecCard extends StatelessWidget {
  final Rfq rfq;
  const _SpecCard({required this.rfq});

  @override
  Widget build(BuildContext context) {
    final s = rfq.spec;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Specification',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            _Row('Item', s.item),
            _Row('Quantity', '${s.quantity} ${s.unit}'),
            if (s.standard.isNotEmpty) _Row('Standard', s.standard),
            if (s.grade.isNotEmpty) _Row('Grade', s.grade),
            _Row('Delivery Days', '${s.deliveryDays} days'),
            _Row('Delivery Location', s.deliveryLocation),
            if (s.qualityNotes.isNotEmpty)
              _Row('Quality Notes', s.qualityNotes),
            if (rfq.freeText != null && rfq.freeText!.isNotEmpty) ...[
              const Divider(height: 16),
              Text(
                'Additional Notes:',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                rfq.freeText!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
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
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Bid ranking card (PRD §15.4 formula)
// ──────────────────────────────────────────────────────────────────────────────

class _BidRankingCard extends StatelessWidget {
  final Rfq rfq;
  final ({double price, double delivery, double trust}) weights;
  const _BidRankingCard({required this.rfq, required this.weights});

  @override
  Widget build(BuildContext context) {
    final evaluator = BidEvaluator(
      priceWeight: weights.price,
      deliveryWeight: weights.delivery,
      trustWeight: weights.trust,
    );
    final scored = evaluator.evaluate(rfq.bids);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Bid Rankings',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const Spacer(),
                Text(
                  '${rfq.bids.length} bid${rfq.bids.length == 1 ? '' : 's'}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Price ${(weights.price * 100).toStringAsFixed(0)}% · '
              'Delivery ${(weights.delivery * 100).toStringAsFixed(0)}% · '
              'Trust ${(weights.trust * 100).toStringAsFixed(0)}%',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            ...scored.map((sb) => _BidRankRow(scored: sb, all: scored)),
          ],
        ),
      ),
    );
  }
}

class _BidRankRow extends StatelessWidget {
  final ScoredBid scored;
  final List<ScoredBid> all;
  const _BidRankRow({required this.scored, required this.all});

  @override
  Widget build(BuildContext context) {
    final bid = scored.bid;
    final isTop = scored.rank == 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isTop ? AppColors.verified.withAlpha(15) : Colors.transparent,
        border: Border.all(
          color: isTop ? AppColors.verified.withAlpha(80) : AppColors.divider,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Rank badge
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isTop ? AppColors.verified : AppColors.textSecondary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '#${scored.rank}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bid.vendorName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          _currencyFmt.format(bid.pricePerUnit),
                          style: const TextStyle(fontSize: 12),
                        ),
                        const Text(' · ', style: TextStyle(fontSize: 12)),
                        Text(
                          '${bid.deliveryDays}d',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TrustScorePill(score: bid.trustScoreAtBid),
                  const SizedBox(height: 2),
                  Text(
                    'Score ${(scored.composite * 100).toStringAsFixed(1)}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isTop ? AppColors.verified : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: isTop
                  ? AppColors.verified.withAlpha(12)
                  : const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 13,
                  color: isTop ? AppColors.verified : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    scored.explain(all),
                    style: TextStyle(
                      fontSize: 11,
                      color: isTop
                          ? const Color(0xFF1B5E20)
                          : AppColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Bid submission form
// ──────────────────────────────────────────────────────────────────────────────

class _BidForm extends StatelessWidget {
  final Rfq rfq;
  final GlobalKey<FormState> formKey;
  final TextEditingController priceCtrl;
  final TextEditingController daysCtrl;
  final TextEditingController notesCtrl;
  final bool submitting;
  final String? error;
  final VoidCallback onSubmit;

  const _BidForm({
    required this.rfq,
    required this.formKey,
    required this.priceCtrl,
    required this.daysCtrl,
    required this.notesCtrl,
    required this.submitting,
    this.error,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Submit Your Bid',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: priceCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Price per unit (₹)',
                  prefixIcon: Icon(Icons.currency_rupee),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (double.tryParse(v.trim()) == null)
                    return 'Invalid number';
                  if (double.parse(v.trim()) <= 0) return 'Must be > 0';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: daysCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Delivery days',
                  prefixIcon: Icon(Icons.local_shipping_outlined),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (int.tryParse(v.trim()) == null) return 'Invalid number';
                  if (int.parse(v.trim()) <= 0) return 'Must be > 0';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: notesCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  hintText: 'Delivery terms, warranty, certifications…',
                  prefixIcon: Icon(Icons.note_outlined),
                ),
              ),

              if (error != null) ...[
                const SizedBox(height: 12),
                Text(
                  error!,
                  style: const TextStyle(color: AppColors.failed, fontSize: 13),
                ),
              ],

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: submitting ? null : onSubmit,
                  icon: submitting
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_outlined),
                  label: Text(submitting ? 'Submitting…' : 'Submit Bid'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BidSubmittedBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.verified.withAlpha(20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.verified),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Your bid has been submitted! Rankings will update as other bids arrive.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.verified),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
