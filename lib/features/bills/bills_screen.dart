import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../core/database/app_database.dart';
import '../../core/providers/currency_provider.dart';
import '../../core/providers/repository_providers.dart';
import '../../shared/widgets/main_shell.dart';
import '../../shared/widgets/shared_widgets.dart';

class BillsScreen extends ConsumerStatefulWidget {
  const BillsScreen({super.key});

  @override
  ConsumerState<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends ConsumerState<BillsScreen> {
  int _tabIndex = 0; // 0: Ice Cube Bills, 1: Dedicated Custom Bills
  String _filter = 'All';
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exchangeRate = ref.watch(exchangeRateProvider);
    final iceBillsAsync = ref.watch(iceBillsStreamProvider);
    final customBillsAsync = ref.watch(customBillsStreamProvider);

    final billsAsync = _tabIndex == 0 ? iceBillsAsync : customBillsAsync;

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppNavigationDrawer(currentLocation: '/bills'),
      appBar: AppHeader(
        title: 'Bills & Invoices',
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.primary),
            onPressed: () => context.go('/bills/create'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Section Tabs: Ice Cube Bills vs Dedicated Custom Bills Section
          Container(
            margin: const EdgeInsets.fromLTRB(
                AppDimensions.containerMargin,
                AppDimensions.md,
                AppDimensions.containerMargin,
                AppDimensions.sm),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03), blurRadius: 8)
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _tabIndex = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _tabIndex == 0
                            ? AppColors.primary
                            : Colors.transparent,
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusMedium),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.ac_unit,
                              size: 16,
                              color: _tabIndex == 0
                                  ? Colors.white
                                  : AppColors.onSurfaceVariant),
                          const SizedBox(width: 6),
                          Text(
                            'Ice Cube Bills',
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _tabIndex == 0
                                  ? Colors.white
                                  : AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _tabIndex = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _tabIndex == 1
                            ? AppColors.secondary
                            : Colors.transparent,
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusMedium),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.style,
                              size: 16,
                              color: _tabIndex == 1
                                  ? Colors.white
                                  : AppColors.onSurfaceVariant),
                          const SizedBox(width: 6),
                          Text(
                            'Custom Bills',
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _tabIndex == 1
                                  ? Colors.white
                                  : AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.containerMargin),
            child: AppSearchBar(
              hint: _tabIndex == 0
                  ? 'Search Ice Bills...'
                  : 'Search Custom Bills...',
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          const SizedBox(height: AppDimensions.sm),

          // Status Filter Chips
          FilterChipRow(
            chips: const ['All', 'Paid', 'Partial', 'Unpaid'],
            selected: _filter,
            onSelected: (v) => setState(() => _filter = v),
          ),

          const SizedBox(height: AppDimensions.sm),

          // Stream Body
          Expanded(
            child: billsAsync.when(
              data: (billsList) {
                final filtered = billsList.where((b) {
                  final matchStatus = _filter == 'All' ||
                      b.status.toLowerCase() == _filter.toLowerCase();
                  final matchQ = _query.isEmpty ||
                      b.id.toLowerCase().contains(_query.toLowerCase()) ||
                      b.customerName.toLowerCase().contains(_query.toLowerCase());
                  return matchStatus && matchQ;
                }).toList();

                if (filtered.isEmpty) {
                  return EmptyStateWidget(
                    icon: _tabIndex == 0
                        ? Icons.receipt_long_outlined
                        : Icons.style_outlined,
                    title: _tabIndex == 0
                        ? 'No Ice Bills Found'
                        : 'No Custom Bills Found',
                    subtitle: 'Tap + above to create a new bill',
                  );
                }

                final totalUnpaid = filtered
                    .where((b) => b.status != 'paid')
                    .fold(0.0, (s, b) => s + b.remainingAmount);

                return ListView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.containerMargin),
                  children: [
                    _BillsSummaryCard(
                      totalUnpaid: totalUnpaid,
                      count: filtered.length,
                      exchangeRate: exchangeRate,
                    ),
                    const SizedBox(height: AppDimensions.md),
                    ...filtered.map((bill) => _BillTile(
                          bill: bill,
                          exchangeRate: exchangeRate,
                        )),
                  ],
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Text('Error loading bills: $err',
                    style: GoogleFonts.manrope(color: AppColors.error)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BillsSummaryCard extends StatelessWidget {
  final double totalUnpaid;
  final int count;
  final double exchangeRate;
  const _BillsSummaryCard(
      {required this.totalUnpaid,
      required this.count,
      required this.exchangeRate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04), blurRadius: 16)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Outstanding Balance',
                  style: GoogleFonts.jetBrainsMono(
                      fontSize: 11, color: AppColors.onSurfaceVariant)),
              StatusChip(
                  label: '$count Bills', color: AppColors.primary),
            ],
          ),
          const SizedBox(height: AppDimensions.xs),
          Text(
            CurrencyFormatter.formatUSD(totalUnpaid),
            style: GoogleFonts.manrope(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.unpaid),
          ),
          Text(
            CurrencyFormatter.formatSYP(totalUnpaid, exchangeRate),
            style: GoogleFonts.jetBrainsMono(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _BillTile extends StatelessWidget {
  final Bill bill;
  final double exchangeRate;
  const _BillTile({required this.bill, required this.exchangeRate});

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (bill.status) {
      'paid' => AppColors.paid,
      'partial' => AppColors.partial,
      _ => AppColors.unpaid,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03), blurRadius: 8)
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: bill.isCustom
                ? AppColors.secondaryContainer
                : AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          ),
          child: Icon(
            bill.isCustom ? Icons.style : Icons.receipt_long,
            color: bill.isCustom ? AppColors.secondary : AppColors.primary,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Text(bill.id,
                style: GoogleFonts.jetBrainsMono(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface)),
            const SizedBox(width: 6),
            if (bill.isCustom)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('Custom',
                    style: GoogleFonts.manrope(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary)),
              ),
          ],
        ),
        subtitle: Text(
          '${bill.customerName} • ${bill.issueDate.toString().substring(0, 10)}',
          style: GoogleFonts.manrope(
              fontSize: 12, color: AppColors.onSurfaceVariant),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(CurrencyFormatter.formatUSD(bill.total),
                style: GoogleFonts.jetBrainsMono(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface)),
            StatusChip(
                label: bill.status.toUpperCase(), color: statusColor),
          ],
        ),
        onTap: () => context.go('/bills/detail', extra: bill),
      ),
    );
  }
}
