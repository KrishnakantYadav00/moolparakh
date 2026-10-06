import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/api/api_client.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize date formatting for India locale
  await initializeDateFormatting('en_IN', null);

  // Initialize API client (loads base URL from prefs)
  await ApiClient.instance.init();

  // Check for existing session (Phase 1 mock session)
  final prefs = await SharedPreferences.getInstance();
  final savedVendorId = prefs.getString('current_vendor_id');

  runApp(
    ProviderScope(
      overrides: [
        if (savedVendorId != null)
          currentVendorIdProvider.overrideWith((ref) => savedVendorId),
      ],
      child: const MoolParakhApp(),
    ),
  );
}

class MoolParakhApp extends ConsumerWidget {
  const MoolParakhApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // If a session exists at startup, redirect to dashboard
    final vendorId = ref.read(currentVendorIdProvider);
    if (vendorId != null && appRouter.routerDelegate.currentConfiguration.uri.path == '/login') {
       WidgetsBinding.instance.addPostFrameCallback((_) {
         appRouter.go('/home/dashboard');
       });
    }

    return MaterialApp.router(
      title: 'MoolParakh Supplier',
      theme: AppTheme.light,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
