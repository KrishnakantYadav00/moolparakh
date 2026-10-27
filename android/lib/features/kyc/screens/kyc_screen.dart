import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../../../shared/widgets/main_shell.dart';
import '../../../core/models/vendor.dart';
import '../../../core/providers/vendors_list_provider.dart';
import '../../../core/theme/app_theme.dart';

class KycScreen extends ConsumerStatefulWidget {
  const KycScreen({super.key});

  @override
  ConsumerState<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends ConsumerState<KycScreen> {
  String _selectedView = 'Calendar';
  final List<String> _views = ['Calendar', 'Upcoming', 'Expired'];

  @override
  Widget build(BuildContext context) {
    final vendorsAsync = ref.watch(vendorsListProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: RefreshIndicator(
        onRefresh: () async {
          HapticFeedback.lightImpact();
          ref.invalidate(vendorsListProvider);
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
                'Compliance',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Stay ahead of vendor certification expiry.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _views.map((view) {
                          final isSelected = _selectedView == view;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(view, style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                color: isSelected ? Colors.white : AppColors.textSecondary,
                              )),
                              selected: isSelected,
                              selectedColor: AppColors.primary,
                              backgroundColor: const Color(0xFFF5F5F5),
                              showCheckmark: false,
                              onSelected: (selected) {
                                if (selected) setState(() => _selectedView = view);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            vendorsAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => SliverFillRemaining(
                child: Center(
                  child: Text('Failed to load compliance data: $e', style: const TextStyle(color: AppColors.failed)),
                ),
              ),
              data: (vendors) {
                // Flatten all documents
                final List<_DocRow> allDocs = [];
                for (final v in vendors) {
                  for (final d in v.documents) {
                    if (d.expirationDate != null) {
                      allDocs.add(_DocRow(vendor: v, doc: d));
                    }
                  }
                }

                allDocs.sort((a, b) => a.doc.expirationDate!.compareTo(b.doc.expirationDate!));
                final now = DateTime.now();
                final upcoming = allDocs.where((r) => r.doc.expirationDate!.isAfter(now)).toList();
                final expired = allDocs.where((r) => r.doc.expirationDate!.isBefore(now)).toList();

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index == 0) {
                          return _buildAttentionCard(expired, upcoming);
                        }
                        
                        final actualIndex = index - 1;
                        List<_DocRow> listToUse = [];
                        if (_selectedView == 'Upcoming' || _selectedView == 'Calendar') listToUse = upcoming;
                        else if (_selectedView == 'Expired') listToUse = expired;

                        if (actualIndex >= listToUse.length) return const SizedBox.shrink();

                        final row = listToUse[actualIndex];
                        final days = row.doc.expirationDate!.difference(now).inDays;
                        
                        Color badgeColor = days < 0 ? AppColors.failed : (days < 30 ? Colors.orange : (days < 60 ? const Color(0xFFF57F17) : AppColors.verified));
                        String badgeText = days < 0 ? 'Expired' : (days < 30 ? '< 30d' : (days < 60 ? '< 60d' : 'Valid'));

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Color(0xFFEEEEEE)),
                          ),
                          elevation: 0,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(row.vendor.legalName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                          const SizedBox(height: 4),
                                          Text(row.doc.type, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: badgeColor.withAlpha(20),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        badgeText,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: badgeColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Expires: ${row.doc.expirationDate!.toLocal().toString().split(' ')[0]}', style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: AppColors.textSecondary)),
                                    Text(days < 0 ? '${days.abs()}d overdue' : '${days}d remaining', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: days < 0 ? AppColors.failed : AppColors.textSecondary)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: _selectedView == 'Calendar' || _selectedView == 'Upcoming' 
                                  ? upcoming.length + 1 
                                  : expired.length + 1,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttentionCard(List<_DocRow> expired, List<_DocRow> upcoming) {
    final now = DateTime.now();
    final within30 = upcoming.where((d) => d.doc.expirationDate!.difference(now).inDays <= 30).length;
    final within60 = upcoming.where((d) => d.doc.expirationDate!.difference(now).inDays > 30 && d.doc.expirationDate!.difference(now).inDays <= 60).length;
    final within90 = upcoming.where((d) => d.doc.expirationDate!.difference(now).inDays > 60 && d.doc.expirationDate!.difference(now).inDays <= 90).length;
    final totalAttention = expired.length + within30 + within60;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Card(
        color: const Color(0xFFFAFAFA),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFEEEEEE)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Attention Required', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const Text('Reminders are sent at 90, 60 and 30 days.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 16),
              Text(totalAttention.toString(), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const Text('certifications require attention', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFEEEEEE)),
              const SizedBox(height: 12),
              _buildStatRow('expired', expired.length.toString()),
              _buildStatRow('within 30 days', within30.toString()),
              _buildStatRow('within 60 days', within60.toString()),
              _buildStatRow('within 90 days', within90.toString()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }
}

class _DocRow {
  final Vendor vendor;
  final VendorDocument doc;
  _DocRow({required this.vendor, required this.doc});
}
