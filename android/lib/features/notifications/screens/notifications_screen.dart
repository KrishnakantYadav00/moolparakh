// lib/features/notifications/screens/notifications_screen.dart
//
// Supplier notifications list.
// Shows high-priority alerts (compliance expiry, new RFQs).
// Polls or receives FCM pushes.
// Supports optimistic mark-as-read.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/notification.dart';
import '../../../core/providers/notifications_provider.dart';
import '../../../core/theme/app_theme.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark all read',
            onPressed: () => ref.read(notificationsProvider.notifier).markAllRead(),
          ),
        ],
      ),
      body: notifsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (notifs) => RefreshIndicator(
          onRefresh: () async =>
              ref.read(notificationsProvider.notifier).refresh(),
          child: notifs.isEmpty
              ? const _EmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: notifs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _NotifCard(notif: notifs[i]),
                ),
        ),
      ),
    );
  }
}

class _NotifCard extends ConsumerWidget {
  final AppNotification notif;
  const _NotifCard({required this.notif});

  IconData get _icon {
    switch (notif.kind) {
      case NotificationKind.high:
        return Icons.priority_high;
      case NotificationKind.critical:
        return Icons.warning_amber_rounded;
      case NotificationKind.compliance:
        return Icons.assignment_late_outlined;
      case NotificationKind.rfq:
        return Icons.request_quote_outlined;
      case NotificationKind.trust:
        return Icons.trending_down;
    }
  }

  Color get _color {
    switch (notif.kind) {
      case NotificationKind.critical:
      case NotificationKind.trust:
        return AppColors.failed;
      case NotificationKind.compliance:
      case NotificationKind.high:
        return AppColors.pending;
      case NotificationKind.rfq:
        return AppColors.primary;
    }
  }

  void _handleTap(BuildContext context, WidgetRef ref) {
    if (!notif.read) {
      ref.read(notificationsProvider.notifier).markRead(notif.id);
    }

    if (notif.kind == NotificationKind.rfq) {
      context.push('/home/rfq');
    } else if (notif.kind == NotificationKind.compliance) {
      context.push('/home/kyc');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      color: notif.read ? AppColors.surfaceCard : AppColors.primary.withAlpha(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _handleTap(context, ref),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _color.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: Icon(_icon, color: _color, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notif.title,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: notif.read ? FontWeight.w500 : FontWeight.w700,
                                ),
                          ),
                        ),
                        Text(
                          notif.ageLabel,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notif.detail,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: notif.read ? AppColors.textSecondary : AppColors.textPrimary,
                          ),
                    ),
                  ],
                ),
              ),
              if (!notif.read) ...[
                const SizedBox(width: 12),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_off_outlined,
                size: 72, color: AppColors.textSecondary.withAlpha(120)),
            const SizedBox(height: 16),
            Text('No notifications',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'You\'re all caught up. RFQ alerts and compliance reminders will appear here.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
