// lib/core/providers/vendors_provider.dart
//
// Riverpod providers for vendor data.
// PRD §5.7 — "Riverpod: compile-safe, does not depend on widget tree, easy to test"

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../models/vendor.dart';

// ──────────────────────────────────────────────────────────────────────────────
// State notifiers
// ──────────────────────────────────────────────────────────────────────────────

class VendorListNotifier extends AsyncNotifier<List<Vendor>> {
  @override
  Future<List<Vendor>> build() => _fetch();

  Future<List<Vendor>> _fetch() async {
    final raw = await ApiClient.instance.listVendors();
    return raw.map((j) => Vendor.fromJson(j)).toList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

class VendorDetailNotifier extends FamilyAsyncNotifier<Vendor, String> {
  @override
  Future<Vendor> build(String vendorId) => _fetch(vendorId);

  Future<Vendor> _fetch(String id) async {
    final raw = await ApiClient.instance.getVendor(id);
    return Vendor.fromJson(raw);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(arg));
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Providers
// ──────────────────────────────────────────────────────────────────────────────

/// All vendors list.
final vendorListProvider =
    AsyncNotifierProvider<VendorListNotifier, List<Vendor>>(
  VendorListNotifier.new,
);

/// Single vendor detail (keyed by vendor ID).
final vendorDetailProvider =
    AsyncNotifierProviderFamily<VendorDetailNotifier, Vendor, String>(
  VendorDetailNotifier.new,
);

/// Derived: vendors filtered by search query.
final vendorSearchQueryProvider = StateProvider<String>((ref) => '');

final filteredVendorListProvider = Provider<AsyncValue<List<Vendor>>>((ref) {
  final vendorsAsync = ref.watch(vendorListProvider);
  final query = ref.watch(vendorSearchQueryProvider).toLowerCase();

  return vendorsAsync.whenData((vendors) {
    if (query.isEmpty) return vendors;
    return vendors.where((v) {
      return v.displayName.toLowerCase().contains(query) ||
          (v.gstin?.toLowerCase().contains(query) ?? false) ||
          (v.udyamNumber?.toLowerCase().contains(query) ?? false) ||
          v.city.toLowerCase().contains(query);
    }).toList();
  });
});
