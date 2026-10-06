// lib/core/providers/rfq_provider.dart

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_client.dart';
import '../models/rfq.dart';

const _rfqCacheKey = 'moolparakh_rfq_cache';

class RfqListNotifier extends AsyncNotifier<List<Rfq>> {
  @override
  Future<List<Rfq>> build() async {
    // 1. Immediately yield cached data if available (0ms render time)
    final prefs = await SharedPreferences.getInstance();
    final cachedStr = prefs.getString(_rfqCacheKey);

    if (cachedStr != null) {
      try {
        final List<dynamic> rawList = jsonDecode(cachedStr);
        final cachedRfqs = rawList.map((j) => Rfq.fromJson(j)).toList();
        state = AsyncData(cachedRfqs);
      } catch (_) {
        // Cache corrupted, ignore
      }
    }

    // 2. Fetch fresh data from network
    return _fetch();
  }

  Future<List<Rfq>> _fetch() async {
    final raw = await ApiClient.instance.listRfqs();
    final rfqs = raw.map((j) => Rfq.fromJson(j)).toList();

    // Save to cache asynchronously
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString(_rfqCacheKey, jsonEncode(raw));
    });

    return rfqs;
  }

  Future<void> refresh() async {
    // We intentionally don't set AsyncLoading here so the UI doesn't jump to a shimmer state
    // when pulling to refresh. It just shows the refresh indicator and keeps the current data.
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
    NotifierProvider<
      BidWeightsNotifier,
      ({double price, double delivery, double trust})
    >(BidWeightsNotifier.new);
