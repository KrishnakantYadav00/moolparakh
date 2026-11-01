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

final GlobalKey<ScaffoldState> mainShellScaffoldKey = GlobalKey<ScaffoldState>();

class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  static const _tabs = [
    (
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      label: 'Dashboard',
      path: '/home/dashboard',
    ),
    (
      icon: Icons.verified_user_outlined,
      activeIcon: Icons.verified_user,
      label: 'My KYC',
      path: '/home/kyc',
    ),
    (
      icon: Icons.request_quote_outlined,
      activeIcon: Icons.request_quote,
      label: 'RFQs',
      path: '/home/rfq',
    ),
    (
      icon: Icons.notifications_outlined,
      activeIcon: Icons.notifications,
      label: 'Alerts',
      path: '/home/notifications',
    ),
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
      key: mainShellScaffoldKey,
      drawer: Drawer(
        backgroundColor: AppColors.surface,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: AppColors.primary),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'MoolParakh',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Enterprise Procurement Portal',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_outlined),
              title: const Text('Overview'),
              onTap: () {
                Navigator.pop(context);
                context.go('/home/dashboard');
              },
            ),
            ListTile(
              leading: const Icon(Icons.business_outlined),
              title: const Text('Vendors'),
              onTap: () {
                Navigator.pop(context);
                context.go('/home/vendors');
              },
            ),
            ListTile(
              leading: const Icon(Icons.verified_user_outlined),
              title: const Text('Compliance (My KYC)'),
              onTap: () {
                Navigator.pop(context);
                context.go('/home/kyc');
              },
            ),
            ListTile(
              leading: const Icon(Icons.auto_graph_outlined),
              title: const Text('Supplier Intelligence'),
              onTap: () {
                Navigator.pop(context);
                context.go('/home/intelligence');
              },
            ),
            ListTile(
              leading: const Icon(Icons.request_quote_outlined),
              title: const Text('RFQs & Bids'),
              onTap: () {
                Navigator.pop(context);
                context.go('/home/rfq');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                context.push('/settings');
              },
            ),
          ],
        ),
      ),
      body: OfflineBanner(child: child),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (i) => context.go(_tabs[i].path),
        items: [
          for (var i = 0; i < _tabs.length; i++)
            BottomNavigationBarItem(
              icon: i == 3 && unread > 0
                  ? Badge(label: Text('$unread'), child: Icon(_tabs[i].icon))
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
