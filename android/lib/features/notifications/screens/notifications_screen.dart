import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../../shared/widgets/main_shell.dart';
import '../../../core/models/notification.dart';
import '../../../core/providers/notifications_provider.dart';
import '../../../core/theme/app_theme.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: RefreshIndicator(
        onRefresh: () async {
          HapticFeedback.lightImpact();
          ref.read(notificationsProvider.notifier).refresh();
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverAppBar(
              floating: true,
              pinned: true,
              elevation: 0,
              backgroundColor: AppColors.surface,
              iconTheme: const IconThemeData(color: AppColors.textPrimary),
              leading: IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  mainShellScaffoldKey.currentState?.openDrawer();
                },
              ),
              title: const Text(
                'Alerts',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 24,
                  letterSpacing: -0.5,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.done_all, color: AppColors.textPrimary),
                  tooltip: 'Mark all read',
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    ref.read(notificationsProvider.notifier).markAllRead();
                  },
                ),
              ],
            ),

            notifsAsync.when(
              loading: () =>
                  const SliverToBoxAdapter(child: _NotificationShimmer()),
              error: (e, _) =>
                  SliverToBoxAdapter(child: Center(child: Text('Error: $e'))),
              data: (notifs) => notifs.isEmpty
                  ? const SliverFillRemaining(child: _EmptyState())
                  : SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          return AnimationConfiguration.staggeredList(
                            position: index,
                            duration: const Duration(milliseconds: 375),
                            child: SlideAnimation(
                              verticalOffset: 50.0,
                              child: FadeInAnimation(
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: _NotifCard(notif: notifs[index]),
                                ),
                              ),
                            ),
                          );
                        }, childCount: notifs.length),
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

class _NotificationShimmer extends StatelessWidget {
  const _NotificationShimmer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(
          6,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Shimmer.fromColors(
              baseColor: AppColors.shimmer,
              highlightColor: AppColors.shimmerHighlight,
              child: Container(
                height: 90,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
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
      color: notif.read
          ? AppColors.surfaceCard
          : AppColors.primary.withAlpha(10),
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
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  fontWeight: notif.read
                                      ? FontWeight.w500
                                      : FontWeight.w700,
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
                        color: notif.read
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
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
            Icon(
              Icons.notifications_off_outlined,
              size: 72,
              color: AppColors.textSecondary.withAlpha(120),
            ),
            const SizedBox(height: 16),
            Text(
              'No notifications',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'You\'re all caught up. RFQ alerts and compliance reminders will appear here.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
