// lib/features/vendors/screens/add_vendor_screen.dart
//
// Form to onboard a new vendor into the MoolParakh platform.
// In real mode: calls ApiClient.instance.createVendor(body).
// In demo mode: shows a SnackBar and pops without hitting the backend.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_client.dart';
import '../../../core/providers/demo_mode_provider.dart';
import '../../../core/theme/app_theme.dart';

class AddVendorScreen extends ConsumerStatefulWidget {
  const AddVendorScreen({super.key});

  @override
  ConsumerState<AddVendorScreen> createState() => _AddVendorScreenState();
}

class _AddVendorScreenState extends ConsumerState<AddVendorScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _legalNameCtrl = TextEditingController();
  final _tradeNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _gstinCtrl = TextEditingController();
  final _panCtrl = TextEditingController();
  final _cinCtrl = TextEditingController();
  final _udyamCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();

  String? _msmeCategory;
  bool _isLoading = false;
  String? _errorText;

  static const _msmeOptions = ['MICRO', 'SMALL', 'MEDIUM'];

  @override
  void dispose() {
    _legalNameCtrl.dispose();
    _tradeNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _gstinCtrl.dispose();
    _panCtrl.dispose();
    _cinCtrl.dispose();
    _udyamCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final isDemo = ref.read(isDemoModeProvider);
    if (isDemo) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Demo mode: vendor not saved to backend. Toggle off Demo Mode in Settings to enable.',
          ),
        ),
      );
      context.pop();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final body = <String, dynamic>{
        'legalName': _legalNameCtrl.text.trim(),
        if (_tradeNameCtrl.text.trim().isNotEmpty)
          'tradeName': _tradeNameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        if (_gstinCtrl.text.trim().isNotEmpty)
          'gstin': _gstinCtrl.text.trim(),
        if (_panCtrl.text.trim().isNotEmpty)
          'pan': _panCtrl.text.trim(),
        if (_cinCtrl.text.trim().isNotEmpty)
          'cin': _cinCtrl.text.trim(),
        if (_udyamCtrl.text.trim().isNotEmpty)
          'udyamNumber': _udyamCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'state': _stateCtrl.text.trim(),
        if (_msmeCategory != null) 'msmeCategory': _msmeCategory,
      };

      await ApiClient.instance.createVendor(body);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vendor added successfully')),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorText = e.toString();
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool required = false,
    bool email = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          hintText: hint,
        ),
        validator: (val) {
          if (required && (val == null || val.trim().isEmpty)) {
            return '$label is required';
          }
          if (email && val != null && val.trim().isNotEmpty) {
            final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
            if (!emailRegex.hasMatch(val.trim())) {
              return 'Enter a valid email address';
            }
          }
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Add Vendor'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Section: Basic Info ──────────────────────────────────────
              const _SectionHeader('Basic Information'),
              const SizedBox(height: 12),
              _field(
                controller: _legalNameCtrl,
                label: 'Legal Name',
                required: true,
              ),
              _field(
                controller: _tradeNameCtrl,
                label: 'Trade Name',
              ),
              _field(
                controller: _emailCtrl,
                label: 'Email',
                required: true,
                email: true,
                keyboardType: TextInputType.emailAddress,
              ),
              _field(
                controller: _phoneCtrl,
                label: 'Phone',
                required: true,
                keyboardType: TextInputType.phone,
              ),

              // ── Section: Tax / Registration ──────────────────────────────
              const _SectionHeader('Tax & Registration'),
              const SizedBox(height: 12),
              _field(
                controller: _gstinCtrl,
                label: 'GSTIN',
                hint: '27AABCA1234B1ZK',
              ),
              _field(
                controller: _panCtrl,
                label: 'PAN',
              ),
              _field(
                controller: _cinCtrl,
                label: 'CIN',
              ),
              _field(
                controller: _udyamCtrl,
                label: 'Udyam Number',
              ),

              // ── Section: Location & Category ────────────────────────────
              const _SectionHeader('Location & Category'),
              const SizedBox(height: 12),
              _field(
                controller: _cityCtrl,
                label: 'City',
                required: true,
              ),
              _field(
                controller: _stateCtrl,
                label: 'State',
                required: true,
              ),

              // MSME Category dropdown
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  value: _msmeCategory,
                  decoration: const InputDecoration(
                    labelText: 'MSME Category',
                  ),
                  items: _msmeOptions
                      .map(
                        (opt) => DropdownMenuItem(
                          value: opt,
                          child: Text(opt),
                        ),
                      )
                      .toList(),
                  onChanged: (val) => setState(() => _msmeCategory = val),
                ),
              ),

              // ── Error text ───────────────────────────────────────────────
              if (_errorText != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorText!,
                  style: const TextStyle(color: AppColors.failed, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: 24),

              // ── Submit button ────────────────────────────────────────────
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text('Add Vendor'),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
