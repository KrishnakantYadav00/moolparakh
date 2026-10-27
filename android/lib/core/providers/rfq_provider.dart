// lib/core/providers/rfq_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../models/rfq.dart';
import '../services/demo_data.dart';
import 'demo_mode_provider.dart';

class RfqListNotifier extends AsyncNotifier<List<Rfq>> {
  @override
  Future<List<Rfq>> build() async {
    final isDemo = ref.watch(isDemoModeProvider);
    if (isDemo) return demoRfqs;
    return _fetch();
  }

  Future<List<Rfq>> _fetch() async {
    final raw = await ApiClient.instance.listRfqs();
    return raw.map((j) => Rfq.fromJson(j)).toList();
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(() async {
      final isDemo = ref.read(isDemoModeProvider);
      if (isDemo) return demoRfqs;
      return _fetch();
    });
  }
}

class RfqDetailNotifier extends FamilyAsyncNotifier<Rfq, String> {
  @override
  Future<Rfq> build(String rfqId) async {
    final isDemo = ref.read(isDemoModeProvider);
    if (isDemo) {
      final found = demoRfqs.where((r) => r.id == rfqId).toList();
      if (found.isNotEmpty) return found.first;
    }
    return _fetch(rfqId);
  }

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

/// Derived: only OPEN RFQs.
final openRfqsProvider = Provider<AsyncValue<List<Rfq>>>((ref) {
  return ref
      .watch(rfqListProvider)
      .whenData(
        (rfqs) => rfqs.where((r) => r.status.isOpen && !r.isClosed).toList(),
      );
});

/// Bid weights — adjustable per-RFQ in the UI.
class BidWeightsNotifier
    extends Notifier<({double price, double delivery, double trust})> {
  @override
  ({double price, double delivery, double trust}) build() =>
      (price: 0.45, delivery: 0.30, trust: 0.25);

  void update(double price, double delivery, double trust) {
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
    NotifierProvider<
      BidWeightsNotifier,
      ({double price, double delivery, double trust})
    >(BidWeightsNotifier.new);
