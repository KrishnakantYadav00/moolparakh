// lib/core/models/rfq.dart
//
// Mirrors backend:
//   prisma/schema.prisma  → Rfq, Bid, RfqStatus
//   frontend/src/lib/api.ts → ApiRfq, ApiBid
//   frontend/src/utils/bidEvaluation.ts → scoring formula
//
// Bid evaluation formula (PRD §15.4):
//   price_score    = 1 - (unit_price - min_price) / (max_price - min_price)
//   delivery_score = 1 - (delivery_days - min_days) / (max_days - min_days)
//   trust_norm     = trust_score / 100
//   composite      = price*0.45 + delivery*0.30 + trust*0.25

import 'package:equatable/equatable.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Enums
// ──────────────────────────────────────────────────────────────────────────────

enum RfqStatus { draft, open, completed, cancelled }

extension RfqStatusX on RfqStatus {
  static RfqStatus fromString(String s) {
    switch (s.toUpperCase()) {
      case 'OPEN':
        return RfqStatus.open;
      case 'COMPLETED':
        return RfqStatus.completed;
      case 'CANCELLED':
        return RfqStatus.cancelled;
      default:
        return RfqStatus.draft;
    }
  }

  String get label {
    switch (this) {
      case RfqStatus.draft:
        return 'Draft';
      case RfqStatus.open:
        return 'Open';
      case RfqStatus.completed:
        return 'Completed';
      case RfqStatus.cancelled:
        return 'Cancelled';
    }
  }

  bool get isOpen => this == RfqStatus.open;
}

// ──────────────────────────────────────────────────────────────────────────────
// Models
// ──────────────────────────────────────────────────────────────────────────────

class RfqSpec extends Equatable {
  final String item;
  final String standard;
  final String grade;
  final int quantity;
  final String unit;
  final int deliveryDays;
  final String deliveryLocation;
  final String qualityNotes;

  const RfqSpec({
    required this.item,
    required this.standard,
    required this.grade,
    required this.quantity,
    required this.unit,
    required this.deliveryDays,
    required this.deliveryLocation,
    required this.qualityNotes,
  });

  factory RfqSpec.fromJson(Map<String, dynamic> j) => RfqSpec(
    item: j['item'] as String? ?? '',
    standard: j['standard'] as String? ?? '',
    grade: j['grade'] as String? ?? '',
    quantity: (j['quantity'] as num?)?.toInt() ?? 0,
    unit: j['unit'] as String? ?? '',
    deliveryDays: (j['deliveryDays'] as num?)?.toInt() ?? 0,
    deliveryLocation: j['deliveryLocation'] as String? ?? '',
    qualityNotes: j['qualityNotes'] as String? ?? '',
  );

  @override
  List<Object?> get props => [item, quantity, unit];
}

class Bid extends Equatable {
  final String id;
  final String rfqId;
  final String vendorId;
  final String vendorName;
  final double pricePerUnit;
  final int deliveryDays;
  final int trustScoreAtBid;
  final String? notes;
  final DateTime submittedAt;

  const Bid({
    required this.id,
    required this.rfqId,
    required this.vendorId,
    required this.vendorName,
    required this.pricePerUnit,
    required this.deliveryDays,
    required this.trustScoreAtBid,
    this.notes,
    required this.submittedAt,
  });

  factory Bid.fromJson(Map<String, dynamic> j) => Bid(
    id: j['id']?.toString() ?? '',
    rfqId: j['rfqId']?.toString() ?? j['rfq_id']?.toString() ?? '',
    vendorId: j['vendorId']?.toString() ?? j['vendor_id']?.toString() ?? '',
    vendorName:
        j['vendorName']?.toString() ?? j['vendor_name']?.toString() ?? '',
    pricePerUnit: (j['pricePerUnit'] as num?)?.toDouble() ??
        (j['price_per_unit'] as num?)?.toDouble() ??
        0.0,
    deliveryDays: (j['deliveryDays'] as num?)?.toInt() ??
        (j['delivery_days'] as num?)?.toInt() ??
        0,
    trustScoreAtBid: (j['trustScoreAtBid'] as num?)?.toInt() ??
        (j['trust_score_at_bid'] as num?)?.toInt() ??
        0,
    notes: j['notes'] as String?,
    submittedAt: DateTime.tryParse(
          j['submittedAt']?.toString() ??
              j['submitted_at']?.toString() ??
              '',
        ) ??
        DateTime.now(),
  );

  @override
  List<Object?> get props => [id, rfqId, vendorId];
}

/// A bid with computed evaluation scores — produced by [BidEvaluator].
class ScoredBid extends Equatable {
  final Bid bid;
  final double priceScore;
  final double deliveryScore;
  final double trustNormalised;
  final double composite;
  final int rank;

  const ScoredBid({
    required this.bid,
    required this.priceScore,
    required this.deliveryScore,
    required this.trustNormalised,
    required this.composite,
    required this.rank,
  });

  /// Contributions of each criterion to the composite score.
  double get priceContribution => priceScore * 0.45;
  double get deliveryContribution => deliveryScore * 0.30;
  double get trustContribution => trustNormalised * 0.25;

  @override
  List<Object?> get props => [bid.id, composite, rank];
}

/// PRD §15.4 — bid evaluation algorithm.
/// Weights: price=0.45, delivery=0.30, trust=0.25
class BidEvaluator {
  final double priceWeight;
  final double deliveryWeight;
  final double trustWeight;

  const BidEvaluator({
    this.priceWeight = 0.45,
    this.deliveryWeight = 0.30,
    this.trustWeight = 0.25,
  });

  /// Evaluate all bids for a single RFQ, returning them in rank order.
  List<ScoredBid> evaluate(List<Bid> bids) {
    if (bids.isEmpty) return [];

    // Extract min/max for normalisation
    final prices = bids.map((b) => b.pricePerUnit).toList();
    final days = bids.map((b) => b.deliveryDays.toDouble()).toList();
    final minPrice = prices.reduce((a, b) => a < b ? a : b);
    final maxPrice = prices.reduce((a, b) => a > b ? a : b);
    final minDays = days.reduce((a, b) => a < b ? a : b);
    final maxDays = days.reduce((a, b) => a > b ? a : b);

    final priceTied = maxPrice == minPrice;
    final daysTied = maxDays == minDays;

    final scored = bids.map((b) {
      // PRD §15.4 normalisation formulas
      final priceScore = priceTied
          ? 0.5 // tied — both get 0.5
          : 1.0 - (b.pricePerUnit - minPrice) / (maxPrice - minPrice);
      final deliveryScore = daysTied
          ? 0.5
          : 1.0 - (b.deliveryDays - minDays) / (maxDays - minDays);
      final trustNorm = b.trustScoreAtBid / 100.0;

      final composite =
          priceScore * priceWeight +
          deliveryScore * deliveryWeight +
          trustNorm * trustWeight;

      return ScoredBid(
        bid: b,
        priceScore: priceScore,
        deliveryScore: deliveryScore,
        trustNormalised: trustNorm,
        composite: composite,
        rank: 0, // assigned below after sort
      );
    }).toList();

    // Sort descending by composite
    scored.sort((a, b) => b.composite.compareTo(a.composite));

    // Assign ranks (1-indexed)
    return List.generate(
      scored.length,
      (i) => ScoredBid(
        bid: scored[i].bid,
        priceScore: scored[i].priceScore,
        deliveryScore: scored[i].deliveryScore,
        trustNormalised: scored[i].trustNormalised,
        composite: scored[i].composite,
        rank: i + 1,
      ),
    );
  }
}

extension ScoredBidExplanation on ScoredBid {
  /// Deterministic explanation matching website ExplainabilityPanel (PRD Phase 3.1)
  String explain(List<ScoredBid> all) {
    if (all.length <= 1) {
      return 'Ranks #$rank with composite score ${(composite * 100).toStringAsFixed(1)}/100.';
    }
    final bids = all.map((s) => s.bid).toList();

    final priceRank = ([...bids]..sort((a, b) => a.pricePerUnit.compareTo(b.pricePerUnit)))
            .indexWhere((b) => b.id == bid.id) +
        1;
    final deliveryRank = ([...bids]..sort((a, b) => a.deliveryDays.compareTo(b.deliveryDays)))
            .indexWhere((b) => b.id == bid.id) +
        1;
    final trustRank = ([...bids]..sort((a, b) => b.trustScoreAtBid.compareTo(a.trustScoreAtBid)))
            .indexWhere((b) => b.id == bid.id) +
        1;

    final strengths = <String>[];
    if (trustRank == 1) {
      strengths.add('highest Trust Score (${bid.trustScoreAtBid})');
    } else if (trustRank == 2) {
      strengths.add('strong trust rating');
    }

    if (deliveryRank == 1) {
      strengths.add('fastest delivery (${bid.deliveryDays}d)');
    } else if (deliveryRank == 2) {
      strengths.add('fast delivery turnaround');
    }

    if (priceRank == 1) {
      strengths.add('lowest unit price');
    } else if (priceRank == 2) {
      strengths.add('competitive pricing');
    }

    final tradeoffs = <String>[];
    if (priceRank > 2) {
      tradeoffs.add('higher unit price than competitors');
    }
    if (deliveryRank > 2) {
      tradeoffs.add('${bid.deliveryDays}-day delivery window');
    }
    if (trustRank > 2) {
      tradeoffs.add('lower trust score (${bid.trustScoreAtBid})');
    }

    final sText = strengths.isNotEmpty ? 'Combines ${strengths.join(' and ')}.' : '';
    final tText = tradeoffs.isNotEmpty ? ' Trade-off: ${tradeoffs.join(', ')}.' : '';
    return 'Ranks #$rank: $sText$tText';
  }
}

class Rfq extends Equatable {
  final String id;
  final String reference;
  final String title;
  final RfqStatus status;
  final RfqSpec spec;
  final String? freeText;
  final int suppliersNotified;
  final DateTime closesAt;
  final String? awardedVendorId;
  final DateTime createdAt;
  final List<Bid> bids;

  const Rfq({
    required this.id,
    required this.reference,
    required this.title,
    required this.status,
    required this.spec,
    this.freeText,
    required this.suppliersNotified,
    required this.closesAt,
    this.awardedVendorId,
    required this.createdAt,
    required this.bids,
  });

  factory Rfq.fromJson(Map<String, dynamic> j) => Rfq(
    id: j['id']?.toString() ?? '',
    reference: j['reference']?.toString() ?? '',
    title: j['title']?.toString() ?? '',
    status: RfqStatusX.fromString((j['status'] ?? 'DRAFT').toString()),
    spec: j['spec'] is Map<String, dynamic>
        ? RfqSpec.fromJson(j['spec'] as Map<String, dynamic>)
        : const RfqSpec(
            item: '',
            standard: '',
            grade: '',
            quantity: 0,
            unit: '',
            deliveryDays: 0,
            deliveryLocation: '',
            qualityNotes: '',
          ),
    freeText: (j['freeText'] ?? j['free_text']) as String?,
    suppliersNotified: ((j['suppliersNotified'] ?? j['suppliers_notified'])
            as num?)
        ?.toInt() ??
        0,
    closesAt: DateTime.tryParse(
          j['closesAt']?.toString() ?? j['closes_at']?.toString() ?? '',
        ) ??
        DateTime.now().add(const Duration(days: 7)),
    awardedVendorId:
        (j['awardedVendorId'] ?? j['awarded_vendor_id']) as String?,
    createdAt: DateTime.tryParse(
          j['createdAt']?.toString() ?? j['created_at']?.toString() ?? '',
        ) ??
        DateTime.now(),
    bids: (j['bids'] as List<dynamic>?)
            ?.map((e) => Bid.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
  );

  Duration get timeRemaining => closesAt.difference(DateTime.now());
  bool get isClosed => !status.isOpen || timeRemaining.isNegative;

  @override
  List<Object?> get props => [id, reference, status];
}
