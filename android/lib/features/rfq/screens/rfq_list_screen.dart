import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../../../shared/widgets/main_shell.dart';
import '../../../core/models/rfq.dart';
import '../../../core/providers/rfq_provider.dart';
import '../../../core/theme/app_theme.dart';

class RfqListScreen extends ConsumerStatefulWidget {
  const RfqListScreen({super.key});

  @override
  ConsumerState<RfqListScreen> createState() => _RfqListScreenState();
}

class _RfqListScreenState extends ConsumerState<RfqListScreen> {
  String _selectedView = 'Open RFQs';
  final List<String> _views = ['Open RFQs', 'Drafts', 'Completed'];

  RfqStatus _mapViewToStatus(String view) {
    switch (view) {
      case 'Drafts': return RfqStatus.draft;
      case 'Completed': return RfqStatus.completed;
      case 'Open RFQs':
      default:
        return RfqStatus.open;
    }
  }

  @override
  Widget build(BuildContext context) {
    final allRfqsAsync = ref.watch(rfqListProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/rfq/create'),
        icon: const Icon(Icons.add),
        label: const Text('Create RFQ'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          HapticFeedback.lightImpact();
          ref.invalidate(rfqListProvider);
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
                'RFQs & Bids',
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
                      'Collect quotes, compare bids on price, delivery and trust.',
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
            allRfqsAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => SliverFillRemaining(
                child: Center(
                  child: Text('Error: $e', style: const TextStyle(color: AppColors.failed)),
                ),
              ),
              data: (all) {
                final targetStatus = _mapViewToStatus(_selectedView);
                final filtered = all.where((r) => r.status == targetStatus).toList();

                if (filtered.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.description_outlined, size: 48, color: AppColors.textSecondary.withAlpha(80)),
                          const SizedBox(height: 16),
                          Text('No ${_selectedView.toLowerCase()}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                          const SizedBox(height: 8),
                          const Text('Create an RFQ to start collecting bids.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        ],
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final rfq = filtered[index];
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
                                  onTap: () => context.push('/home/rfq/${rfq.id}'),
                                  borderRadius: BorderRadius.circular(12),
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
                                                  Text(rfq.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                                  const SizedBox(height: 4),
                                                  Text(rfq.reference, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: rfq.status == RfqStatus.open ? Colors.teal.withAlpha(20) : Colors.grey.withAlpha(20),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                rfq.status.name.toUpperCase(),
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                  color: rfq.status == RfqStatus.open ? Colors.teal : Colors.grey,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        Row(
                                          children: [
                                            Text('${rfq.suppliersNotified} suppliers', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                            const SizedBox(width: 16),
                                            Text('${rfq.bids.length} bids', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                                            const Spacer(),
                                            if (rfq.status == RfqStatus.open)
                                              Text('${rfq.closesAt.difference(DateTime.now()).inHours}h left', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
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
