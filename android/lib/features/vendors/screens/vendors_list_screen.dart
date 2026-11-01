import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/vendor.dart';
import '../../../core/providers/vendors_list_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/main_shell.dart';
import '../../../shared/widgets/status_chip.dart';

class VendorsListScreen extends ConsumerStatefulWidget {
  const VendorsListScreen({super.key});

  @override
  ConsumerState<VendorsListScreen> createState() => _VendorsListScreenState();
}

class _VendorsListScreenState extends ConsumerState<VendorsListScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'All';

  final List<String> _filters = ['All', 'Verified', 'Needs Review', 'High Risk', 'Expired'];

  bool _matchesFilter(Vendor vendor, String filter) {
    if (filter == 'All') return true;
    if (filter == 'Verified') return vendor.status == VendorStatus.verified;
    if (filter == 'Needs Review') return vendor.status == VendorStatus.pendingVerification;
    if (filter == 'High Risk') return (vendor.trustScore?.overallScore ?? 100) < 50;
    if (filter == 'Expired') return false; // Needs compliance check logic, keeping false for now as a mock
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final vendorsAsync = ref.watch(vendorsListProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/vendors/add'),
        icon: const Icon(Icons.add),
        label: const Text('Add Vendor'),
      ),
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
                'Vendors',
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
                      'Manage verification, trust and compliance across your network.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: 'Search vendors...',
                        prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _filters.map((filter) {
                          final isSelected = _selectedFilter == filter;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(filter, style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                color: isSelected ? Colors.white : AppColors.textSecondary,
                              )),
                              selected: isSelected,
                              selectedColor: AppColors.primary,
                              backgroundColor: const Color(0xFFF5F5F5),
                              showCheckmark: false,
                              onSelected: (selected) {
                                if (selected) setState(() => _selectedFilter = filter);
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
                  child: Text('Failed to load vendors: $e', style: const TextStyle(color: AppColors.failed)),
                ),
              ),
              data: (vendors) {
                final filtered = vendors.where((v) {
                  if (!_matchesFilter(v, _selectedFilter)) return false;
                  if (_searchQuery.isEmpty) return true;
                  final q = _searchQuery.toLowerCase();
                  return v.legalName.toLowerCase().contains(q) ||
                         (v.gstin?.toLowerCase().contains(q) ?? false) ||
                         v.city.toLowerCase().contains(q);
                }).toList();

                if (filtered.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(
                      child: Text('No vendors match this view.', style: TextStyle(color: AppColors.textSecondary)),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final vendor = filtered[index];
                        final score = vendor.trustScore?.overallScore ?? 0;
                        return AnimationConfiguration.staggeredList(
                          position: index,
                          duration: const Duration(milliseconds: 375),
                          child: SlideAnimation(
                            verticalOffset: 50.0,
                            child: FadeInAnimation(
                              child: Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: const BorderSide(color: Color(0xFFEEEEEE)),
                                ),
                                elevation: 0,
                                child: InkWell(
                                  onTap: () {
                                    context.push('/vendor/${vendor.id}');
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(vendor.legalName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                                  const SizedBox(height: 4),
                                                  Text(vendor.gstin ?? 'No GSTIN', style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: AppColors.textSecondary)),
                                                ],
                                              ),
                                            ),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Text(score.toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                                                Text('TRUST', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            StatusChip.vendorStatus(vendor.status.name),
                                            const SizedBox(width: 8),
                                            Text('${vendor.msmeCategory.name.toUpperCase()} · ${vendor.city}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: filtered.length,
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
}
