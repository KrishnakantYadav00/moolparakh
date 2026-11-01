// lib/core/providers/demo_mode_provider.dart
//
// Global toggle: when ON, all data providers return rich sample data
// instead of hitting the real backend. Persisted across app restarts.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kDemoModeKey = 'moolparakh_demo_mode';

class DemoModeNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kDemoModeKey) ?? false;
  }

  Future<void> toggle() async {
    final current = state.valueOrNull ?? false;
    final next = !current;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDemoModeKey, next);
    state = AsyncData(next);
  }

  Future<void> set(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDemoModeKey, value);
    state = AsyncData(value);
  }
}

final demoModeProvider = AsyncNotifierProvider<DemoModeNotifier, bool>(
  DemoModeNotifier.new,
);

/// Synchronous convenience — returns false while loading
final isDemoModeProvider = Provider<bool>((ref) {
  return ref.watch(demoModeProvider).valueOrNull ?? false;
});
