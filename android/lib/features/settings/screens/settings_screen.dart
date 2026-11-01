import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/demo_mode_provider.dart';
import '../../../core/providers/vendors_list_provider.dart';
import '../../../core/providers/rfq_provider.dart';
import '../../../core/providers/intelligence_provider.dart';
import '../../auth/screens/login_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _ipController = TextEditingController();
  bool _remind90 = true;
  bool _remind60 = true;
  bool _remind30 = true;
  bool _ipSaved = false;

  @override
  void initState() {
    super.initState();
    _ipController.text = ApiClient.instance.currentBaseUrl
        .replaceFirst('http://', '');
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  void _saveNetworkSettings() async {
    HapticFeedback.lightImpact();
    final raw = _ipController.text.trim();
    if (raw.isEmpty) return;
    final url = raw.startsWith('http') ? raw : 'http://$raw';
    await ApiClient.instance.setBaseUrl(url);
    setState(() => _ipSaved = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _ipSaved = false);
  }

  void _logout() async {
    HapticFeedback.mediumImpact();
    ref.read(currentVendorIdProvider.notifier).state = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_vendor_id');
    if (mounted) context.go('/login');
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(top: 28, bottom: 8, left: 4),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: AppColors.textSecondary,
          ),
        ),
      );

  Widget _card({required Widget child}) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: child,
      );

  Widget _divider() => const Divider(height: 1, color: Color(0xFFEEEEEE), indent: 16, endIndent: 16);

  Widget _rowLabel(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          ],
        ),
      );

  Widget _weightRow(String label, String pct) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
            Text(pct, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
          ],
        ),
      );

  Widget _sourceRow(String label, String source) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary))),
            const SizedBox(width: 8),
            Text(source, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final isDemoAsync = ref.watch(demoModeProvider);
    final isDemo = isDemoAsync.valueOrNull ?? false;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Settings',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 20)),
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFEEEEEE)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [

          // ── DEMO MODE (TOP — most prominent) ──────────────────────
          _sectionLabel('DEMO MODE'),
          _card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDemo ? Colors.green.withAlpha(25) : Colors.grey.withAlpha(20),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isDemo ? Icons.play_circle : Icons.circle_outlined,
                              size: 14,
                              color: isDemo ? Colors.green : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isDemo ? 'DEMO ON' : 'DEMO OFF',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isDemo ? Colors.green : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Switch(
                        value: isDemo,
                        activeColor: Colors.green,
                        onChanged: (_) async {
                          HapticFeedback.lightImpact();
                          await ref.read(demoModeProvider.notifier).toggle();
                          // Refresh all data providers
                          ref.invalidate(vendorsListProvider);
                          ref.invalidate(rfqListProvider);
                          ref.invalidate(intelligenceProvider);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Demo Mode',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isDemo
                        ? 'Showing rich sample data — 6 vendors, 4 RFQs, 5 disruption events. No backend required.'
                        : 'Turn on to show sample data without needing a backend connection. Perfect for presentations.',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                  ),
                  if (isDemo) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withAlpha(15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.withAlpha(50)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle, size: 16, color: Colors.green),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '6 vendors · 4 RFQs · 5 disruption events · Expiry alerts active',
                              style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ── NETWORK / IP ─────────────────────────────────────────
          _sectionLabel('NETWORK'),
          _card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Backend API Address',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  const Text(
                    'Enter your PC\'s Wi-Fi IP. Find it with: Settings → Wi-Fi → (your network) → IP address.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _ipController,
                    keyboardType: TextInputType.url,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 15),
                    decoration: InputDecoration(
                      hintText: '192.168.x.x:5000',
                      prefixIcon: const Icon(Icons.wifi, color: AppColors.primary),
                      suffixIcon: _ipSaved
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : null,
                      filled: true,
                      fillColor: AppColors.surface,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saveNetworkSettings,
                      icon: const Icon(Icons.save_outlined, size: 18),
                      label: const Text('Save & Reconnect'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── ORGANISATION ─────────────────────────────────────────
          _sectionLabel('ORGANISATION'),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 14, 16, 4),
                  child: Text('Organisation', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Text('Managed by your account administrator.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ),
                _divider(),
                _rowLabel('Legal name', 'Apex Components Pvt. Ltd.'),
                _divider(),
                _rowLabel('Signed-in user', 'R. Iyer'),
                _divider(),
                _rowLabel('Role', 'Procurement Admin'),
                _divider(),
                _rowLabel('Plants', '2'),
                const SizedBox(height: 4),
              ],
            ),
          ),

          // ── COMPLIANCE REMINDERS ─────────────────────────────────
          _sectionLabel('COMPLIANCE REMINDERS'),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 14, 16, 4),
                  child: Text('Compliance reminders', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Text('When to alert your team before a vendor document expires.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ),
                _divider(),
                _ComplianceToggle(
                  label: '90 days before expiry',
                  desc: 'Early notice so the vendor has time to renew.',
                  value: _remind90,
                  onChanged: (v) => setState(() => _remind90 = v),
                ),
                _divider(),
                _ComplianceToggle(
                  label: '60 days before expiry',
                  desc: 'Moves the certificate into the Attention Required panel.',
                  value: _remind60,
                  onChanged: (v) => setState(() => _remind60 = v),
                ),
                _divider(),
                _ComplianceToggle(
                  label: '30 days before expiry',
                  desc: 'Final reminder before certification freshness drops.',
                  value: _remind30,
                  onChanged: (v) => setState(() => _remind30 = v),
                ),
              ],
            ),
          ),

          // ── TRUST SCORE WEIGHTING ─────────────────────────────────
          _sectionLabel('VENDOR TRUST SCORE WEIGHTING'),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 14, 16, 4),
                  child: Text('Vendor Trust Score weighting', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Text('The formula applied to every vendor on the network.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ),
                _divider(),
                _weightRow('Verification Completeness', '40%'),
                _divider(),
                _weightRow('Certification Freshness', '35%'),
                _divider(),
                _weightRow('Account Age & Activity', '15%'),
                _divider(),
                _weightRow('Manual Buyer Flag', '10%'),
                const SizedBox(height: 4),
              ],
            ),
          ),

          // ── DEFAULT BID WEIGHTS ───────────────────────────────────
          _sectionLabel('DEFAULT BID WEIGHTS'),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 14, 16, 4),
                  child: Text('Default bid weights', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Text('Starting position for every bid comparison. Buyers can adjust per RFQ.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ),
                _divider(),
                _weightRow('Price', '45%'),
                _divider(),
                _weightRow('Delivery', '30%'),
                _divider(),
                _weightRow('Trust', '25%'),
                const SizedBox(height: 4),
              ],
            ),
          ),

          // ── VERIFICATION DATA SOURCES ─────────────────────────────
          _sectionLabel('VERIFICATION DATA SOURCES'),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 14, 16, 4),
                  child: Text('Verification data sources', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Text('Used during vendor onboarding and re-checks.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ),
                _divider(),
                _sourceRow('GSTIN status and filing history', 'GST Network'),
                _divider(),
                _sourceRow('PAN linkage', 'Income Tax verification service'),
                _divider(),
                _sourceRow('Udyam registration and MSME category', 'Udyam portal'),
                _divider(),
                _sourceRow('CIN and director details', 'MCA registry'),
                const SizedBox(height: 4),
              ],
            ),
          ),

          // ── ACCOUNT ───────────────────────────────────────────────
          _sectionLabel('ACCOUNT'),
          _card(
            child: ListTile(
              leading: const Icon(Icons.logout, color: Color(0xFFDC2626)),
              title: const Text('Log Out',
                  style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w600)),
              trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
              onTap: _logout,
            ),
          ),

          const SizedBox(height: 20),
          const Center(
            child: Text(
              'MoolParakh Supplier Portal v1.0.0',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ComplianceToggle extends StatelessWidget {
  final String label;
  final String desc;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ComplianceToggle({
    required this.label,
    required this.desc,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(desc,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}
