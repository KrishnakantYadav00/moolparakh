// lib/features/rfq/screens/create_rfq_screen.dart
//
// Form screen for creating a new RFQ (Request for Quotation).
// In real mode: calls ApiClient.instance.createRfq(body).
// In demo mode: shows a SnackBar and pops without hitting the backend.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_client.dart';
import '../../../core/models/rfq.dart';
import '../../../core/providers/demo_mode_provider.dart';
import '../../../core/providers/rfq_provider.dart';
import '../../../core/services/demo_data.dart';
import '../../../core/theme/app_theme.dart';

class CreateRfqScreen extends ConsumerStatefulWidget {
  const CreateRfqScreen({super.key});

  @override
  ConsumerState<CreateRfqScreen> createState() => _CreateRfqScreenState();
}

class _CreateRfqScreenState extends ConsumerState<CreateRfqScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _titleCtrl = TextEditingController();
  final _itemCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController();
  final _unitCtrl = TextEditingController();
  final _standardCtrl = TextEditingController();
  final _gradeCtrl = TextEditingController();
  final _deliveryDaysCtrl = TextEditingController();
  final _deliveryLocationCtrl = TextEditingController();
  final _qualityNotesCtrl = TextEditingController();
  final _freeTextCtrl = TextEditingController();

  DateTime? _closesAt;
  bool _isLoading = false;
  String? _errorText;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _itemCtrl.dispose();
    _quantityCtrl.dispose();
    _unitCtrl.dispose();
    _standardCtrl.dispose();
    _gradeCtrl.dispose();
    _deliveryDaysCtrl.dispose();
    _deliveryLocationCtrl.dispose();
    _qualityNotesCtrl.dispose();
    _freeTextCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _closesAt ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _closesAt = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_closesAt == null) {
      setState(() => _errorText = 'Please select a closing date.');
      return;
    }

    final isDemo = ref.read(isDemoModeProvider);
    if (isDemo) {
      final now = DateTime.now();
      final newRfq = Rfq(
        id: 'rfq-demo-${now.millisecondsSinceEpoch}',
        reference: 'RFQ-${now.year}-${demoRfqs.length + 101}',
        title: _titleCtrl.text.trim(),
        status: RfqStatus.open,
        spec: RfqSpec(
          item: _itemCtrl.text.trim(),
          standard: _standardCtrl.text.trim(),
          grade: _gradeCtrl.text.trim(),
          quantity: int.tryParse(_quantityCtrl.text.trim()) ?? 100,
          unit: _unitCtrl.text.trim().isEmpty ? 'pcs' : _unitCtrl.text.trim(),
          deliveryDays: int.tryParse(_deliveryDaysCtrl.text.trim()) ?? 14,
          deliveryLocation: _deliveryLocationCtrl.text.trim(),
          qualityNotes: _qualityNotesCtrl.text.trim(),
        ),
        freeText: _freeTextCtrl.text.trim().isEmpty ? null : _freeTextCtrl.text.trim(),
        suppliersNotified: demoVendors.length,
        closesAt: _closesAt!,
        createdAt: now,
        bids: const [],
      );
      demoRfqs.insert(0, newRfq);
      ref.invalidate(rfqListProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('RFQ published to demo network')),
      );
      context.pop();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final now = DateTime.now();
      await ApiClient.instance.createRfq({
        'reference': 'RFQ-${now.year}-${now.millisecond}',
        'title': _titleCtrl.text.trim(),
        'spec': {
          'item': _itemCtrl.text.trim(),
          'standard': _standardCtrl.text.trim(),
          'grade': _gradeCtrl.text.trim(),
          'quantity': double.parse(_quantityCtrl.text.trim()),
          'unit': _unitCtrl.text.trim(),
          'deliveryDays': int.parse(_deliveryDaysCtrl.text.trim()),
          'deliveryLocation': _deliveryLocationCtrl.text.trim(),
          'qualityNotes': _qualityNotesCtrl.text.trim(),
        },
        'freeText': _freeTextCtrl.text.trim(),
        'closesAt': _closesAt!.toIso8601String(),
      });

      ref.invalidate(rfqListProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('RFQ created successfully')),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorText = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    bool required = false,
    bool numeric = false,
    bool decimal = false,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType ??
            (numeric
                ? TextInputType.number
                : maxLines > 1
                    ? TextInputType.multiline
                    : TextInputType.text),
        inputFormatters: numeric
            ? [
                FilteringTextInputFormatter.allow(
                  decimal ? RegExp(r'^\d*\.?\d*') : RegExp(r'^\d*'),
                ),
              ]
            : null,
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
        ),
        validator: (val) {
          if (required && (val == null || val.trim().isEmpty)) {
            return '$label is required';
          }
          if (numeric && val != null && val.trim().isNotEmpty) {
            if (decimal) {
              if (double.tryParse(val.trim()) == null) {
                return 'Enter a valid number';
              }
            } else {
              if (int.tryParse(val.trim()) == null) {
                return 'Enter a valid whole number';
              }
            }
          }
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = _closesAt != null
        ? DateFormat('dd MMM yyyy').format(_closesAt!)
        : 'Select date *';

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Create RFQ'),
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
              // ── Section: RFQ Basics ──────────────────────────────────────
              const _SectionHeader('RFQ Details'),
              const SizedBox(height: 12),
              _field(
                controller: _titleCtrl,
                label: 'RFQ Title',
                required: true,
              ),

              // ── Section: Item Specification ──────────────────────────────
              const _SectionHeader('Item Specification'),
              const SizedBox(height: 12),
              _field(
                controller: _itemCtrl,
                label: 'Item / Material',
                required: true,
              ),
              _field(
                controller: _quantityCtrl,
                label: 'Quantity',
                required: true,
                numeric: true,
                decimal: true,
              ),
              _field(
                controller: _unitCtrl,
                label: 'Unit (kg / pcs / MT etc.)',
                required: true,
              ),
              _field(
                controller: _standardCtrl,
                label: 'Standard (IS:513, ISO etc.)',
              ),
              _field(
                controller: _gradeCtrl,
                label: 'Grade',
              ),

              // ── Section: Delivery ────────────────────────────────────────
              const _SectionHeader('Delivery'),
              const SizedBox(height: 12),
              _field(
                controller: _deliveryDaysCtrl,
                label: 'Delivery Days Required',
                required: true,
                numeric: true,
              ),
              _field(
                controller: _deliveryLocationCtrl,
                label: 'Delivery Location',
                required: true,
              ),

              // ── Section: Additional ──────────────────────────────────────
              const _SectionHeader('Additional'),
              const SizedBox(height: 12),
              _field(
                controller: _qualityNotesCtrl,
                label: 'Quality Notes',
                maxLines: 3,
              ),

              // Closes At — date picker
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(10),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Closes On *',
                      suffixIcon: const Icon(
                        Icons.calendar_today_outlined,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      errorText: _closesAt == null && _errorText != null
                          ? null // handled in the general error block
                          : null,
                    ),
                    child: Text(
                      dateLabel,
                      style: TextStyle(
                        color: _closesAt != null
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),

              _field(
                controller: _freeTextCtrl,
                label: 'Additional Notes',
                maxLines: 4,
              ),

              // ── Error text ───────────────────────────────────────────────
              if (_errorText != null) ...[
                const SizedBox(height: 4),
                Text(
                  _errorText!,
                  style: const TextStyle(
                    color: AppColors.failed,
                    fontSize: 13,
                  ),
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
                      : const Text('Create RFQ'),
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
