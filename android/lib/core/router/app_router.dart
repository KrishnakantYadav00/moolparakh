// lib/core/router/app_router.dart
//
// GoRouter navigation — all routes for the MoolParakh supplier app.
//
// Route tree:
//   /                        → splash / redirect
//   /login                   → LoginScreen
//   /home                    → shell with bottom nav
//     /home/dashboard        → DashboardScreen
//     /home/kyc              → KycScreen  (own vendor profile)
//     /home/rfq              → RfqListScreen
//     /home/notifications    → NotificationsScreen
//   /rfq/:rfqId              → RfqDetailScreen
//   /kyc/upload              → DocumentUploadScreen
//   /kyc/status/:vendorId    → DocumentStatusScreen
//   /trust/:vendorId         → TrustScoreScreen
//   /settings                → SettingsScreen

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/screens/login_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/kyc/screens/kyc_screen.dart';
import '../../features/kyc/screens/document_upload_screen.dart';
import '../../features/kyc/screens/document_status_screen.dart';
import '../../features/trust_score/screens/trust_score_screen.dart';
import '../../features/rfq/screens/rfq_list_screen.dart';
import '../../features/rfq/screens/rfq_detail_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../shared/widgets/main_shell.dart';

final appRouter = GoRouter(
  initialLocation: '/home/dashboard',
  debugLogDiagnostics: true,
  routes: [
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (_, __) => const LoginScreen(),
    ),

    // Shell route — contains bottom nav bar
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: '/home/dashboard',
          name: 'dashboard',
          builder: (_, __) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/home/kyc',
          name: 'kyc',
          builder: (_, __) => const KycScreen(),
        ),
        GoRoute(
          path: '/home/rfq',
          name: 'rfq-list',
          builder: (_, __) => const RfqListScreen(),
        ),
        GoRoute(
          path: '/home/notifications',
          name: 'notifications',
          builder: (_, __) => const NotificationsScreen(),
        ),
      ],
    ),

    // Detail routes (pushed on top of shell)
    GoRoute(
      path: '/rfq/:rfqId',
      name: 'rfq-detail',
      builder: (_, state) =>
          RfqDetailScreen(rfqId: state.pathParameters['rfqId']!),
    ),
    GoRoute(
      path: '/kyc/upload',
      name: 'doc-upload',
      builder: (_, state) => DocumentUploadScreen(
        vendorId: state.uri.queryParameters['vendorId'] ?? '',
      ),
    ),
    GoRoute(
      path: '/kyc/status/:vendorId',
      name: 'doc-status',
      builder: (_, state) => DocumentStatusScreen(
        vendorId: state.pathParameters['vendorId']!,
      ),
    ),
    GoRoute(
      path: '/trust/:vendorId',
      name: 'trust-score',
      builder: (_, state) => TrustScoreScreen(
        vendorId: state.pathParameters['vendorId']!,
      ),
    ),
  ],

  errorBuilder: (_, state) => Scaffold(
    body: Center(
      child: Text('Page not found: ${state.error}'),
    ),
  ),
);
