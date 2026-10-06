// lib/shared/widgets/main_shell.dart
//
// Bottom navigation shell — surrounds all /home/* routes.
// Tabs: Dashboard | KYC | RFQ | Notifications
//
// The notification badge count comes from unreadNotificationCountProvider.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/notifications_provider.dart';
import '../../core/theme/app_theme.dart';
import 'offline_banner.dart';

class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  static const _tabs = [
    (icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Dashboard', path: '/home/dashboard'),
    (icon: Icons.verified_user_outlined, activeIcon: Icons.verified_user, label: 'My KYC', path: '/home/kyc'),
    (icon: Icons.request_quote_outlined, activeIcon: Icons.request_quote, label: 'RFQs', path: '/home/rfq'),
    (icon: Icons.notifications_outlined, activeIcon: Icons.notifications, label: 'Alerts', path: '/home/notifications'),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    for (var i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadNotificationCountProvider);
    final currentIndex = _currentIndex(context);

    return Scaffold(
      body: OfflineBanner(child: child),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (i) => context.go(_tabs[i].path),
        items: [
          for (var i = 0; i < _tabs.length; i++)
            BottomNavigationBarItem(
              icon: i == 3 && unread > 0
                  ? Badge(
                      label: Text('$unread'),
                      child: Icon(_tabs[i].icon),
                    )
                  : Icon(_tabs[i].icon),
              activeIcon: i == 3 && unread > 0
                  ? Badge(
                      label: Text('$unread'),
                      child: Icon(_tabs[i].activeIcon),
                    )
                  : Icon(_tabs[i].activeIcon),
              label: _tabs[i].label,
            ),
        ],
      ),
    );
  }
}
