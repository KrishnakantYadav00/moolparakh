import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/api/api_client.dart';
import '../../../core/providers/demo_mode_provider.dart';
import '../../../core/providers/vendors_list_provider.dart';
import '../../../core/providers/rfq_provider.dart';
import '../../../core/providers/intelligence_provider.dart';

// Simple provider to hold the currently "logged in" vendor ID.
final currentVendorIdProvider = StateProvider<String?>((ref) => null);

const _demoVendorId = 'demo-user';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vendorIdCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  bool _demoLoading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _vendorIdCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    try {
      await ApiClient.instance.getVendor(_vendorIdCtrl.text.trim());
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_vendor_id', _vendorIdCtrl.text.trim());
      ref.read(currentVendorIdProvider.notifier).state = _vendorIdCtrl.text.trim();
      if (mounted) context.go('/home/dashboard');
    } catch (e) {
      setState(() {
        _error = 'Could not reach the backend or vendor not found.\n'
            'Check your Wi-Fi IP in the hint text above, or use Demo Mode below.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _enterDemoMode() async {
    setState(() { _demoLoading = true; _error = null; });

    // 1. Enable demo mode
    await ref.read(demoModeProvider.notifier).set(true);

    // 2. Set a placeholder vendor ID so the router lets us through
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_vendor_id', _demoVendorId);
    ref.read(currentVendorIdProvider.notifier).state = _demoVendorId;

    // 3. Refresh all data providers so they serve demo data
    ref.invalidate(vendorsListProvider);
    ref.invalidate(rfqListProvider);
    ref.invalidate(intelligenceProvider);

    if (mounted) context.go('/home/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),

              // Logo / brand
              Row(
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.verified_user, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('MoolParakh',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.primary, fontWeight: FontWeight.w700)),
                      Text('Supplier Portal',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 48),

              Text('Welcome back', style: Theme.of(context).textTheme.displayLarge),
              const SizedBox(height: 8),
              Text('Sign in with your Vendor ID to manage KYC documents and respond to RFQs.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary)),

              const SizedBox(height: 40),

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _vendorIdCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Vendor ID',
                        hintText: 'e.g. e61c28fd-1b24-463b-80d9-537f8f1fe637',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'Enter any password',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
                    ),

                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.failed.withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(_error!,
                            style: const TextStyle(color: AppColors.failed, fontSize: 13)),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // ── SIGN IN BUTTON ─────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _login,
                        child: _loading
                            ? const SizedBox(height: 20, width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Sign In'),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── DEMO MODE DIVIDER ──────────────────────────
                    Row(
                      children: const [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('or', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ── DEMO MODE BUTTON ───────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _demoLoading ? null : _enterDemoMode,
                        icon: _demoLoading
                            ? const SizedBox(height: 16, width: 16,
                                child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.play_circle_outline, color: Colors.green),
                        label: Text(
                          _demoLoading ? 'Starting Demo...' : 'Continue in Demo Mode',
                          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Colors.green),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),
                    const Text(
                      'No backend needed — loads 6 vendors, 4 RFQs and live disruption feed.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primaryLight.withAlpha(80)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 16, color: AppColors.primaryLight),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Real login: Enter a valid Vendor UUID from the seeded database. '
                        'Backend must be running at the IP set in Settings.',
                        style: TextStyle(fontSize: 12, color: AppColors.primaryLight),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
