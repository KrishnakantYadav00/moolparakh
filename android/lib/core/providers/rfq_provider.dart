// lib/core/providers/rfq_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../models/rfq.dart';

class RfqListNotifier extends AsyncNotifier<List<Rfq>> {
  @override
  Future<List<Rfq>> build() => _fetch();

  Future<List<Rfq>> _fetch() async {
    final raw = await ApiClient.instance.listRfqs();
    return raw.map((j) => Rfq.fromJson(j)).toList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

class RfqDetailNotifier extends FamilyAsyncNotifier<Rfq, String> {
  @override
  Future<Rfq> build(String rfqId) => _fetch(rfqId);

  Future<Rfq> _fetch(String id) async {
    final raw = await ApiClient.instance.getRfq(id);
    return Rfq.fromJson(raw);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(arg));
  }
}

final rfqListProvider = AsyncNotifierProvider<RfqListNotifier, List<Rfq>>(
  RfqListNotifier.new,
);

final rfqDetailProvider =
    AsyncNotifierProviderFamily<RfqDetailNotifier, Rfq, String>(
  RfqDetailNotifier.new,
);

/// Derived: only OPEN RFQs the supplier can bid on.
final openRfqsProvider = Provider<AsyncValue<List<Rfq>>>((ref) {
  return ref.watch(rfqListProvider).whenData(
        (rfqs) => rfqs.where((r) => r.status.isOpen && !r.isClosed).toList(),
      );
});

/// Bid weights — adjustable per-RFQ in the UI.
class BidWeightsNotifier extends Notifier<({double price, double delivery, double trust})> {
  @override
  ({double price, double delivery, double trust}) build() =>
      (price: 0.45, delivery: 0.30, trust: 0.25);

  void update(double price, double delivery, double trust) {
    // Normalise so they always sum to 1.0
    final total = price + delivery + trust;
    state = (
      price: price / total,
      delivery: delivery / total,
      trust: trust / total,
    );
  }

  void reset() {
    state = (price: 0.45, delivery: 0.30, trust: 0.25);
  }
}

final bidWeightsProvider =
    NotifierProvider<BidWeightsNotifier, ({double price, double delivery, double trust})>(
  BidWeightsNotifier.new,
);
