// lib/core/providers/notifications_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../models/notification.dart';
import '../services/demo_data.dart';
import 'demo_mode_provider.dart';

class NotificationsNotifier extends AsyncNotifier<List<AppNotification>> {
  @override
  Future<List<AppNotification>> build() async {
    final isDemo = ref.watch(isDemoModeProvider);
    if (isDemo) return demoNotifications;
    return _fetch();
  }

  Future<List<AppNotification>> _fetch() async {
    final raw = await ApiClient.instance.listNotifications();
    final list = raw.map((j) => AppNotification.fromJson(j)).toList();
    // Newest first
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final isDemo = ref.read(isDemoModeProvider);
      if (isDemo) return demoNotifications;
      return _fetch();
    });
  }

  Future<void> markRead(String id) async {
    await ApiClient.instance.markNotificationRead(id);
    state = state.whenData(
      (list) =>
          list.map((n) => n.id == id ? n.copyWith(read: true) : n).toList(),
    );
  }

  Future<void> markAllRead() async {
    await ApiClient.instance.markAllNotificationsRead();
    state = state.whenData(
      (list) => list.map((n) => n.copyWith(read: true)).toList(),
    );
  }
}

final notificationsProvider =
    AsyncNotifierProvider<NotificationsNotifier, List<AppNotification>>(
      NotificationsNotifier.new,
    );

/// Unread count badge — used in the bottom nav bar.
final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref
          .watch(notificationsProvider)
          .whenData((list) => list.where((n) => !n.read).length)
          .valueOrNull ??
      0;
});
