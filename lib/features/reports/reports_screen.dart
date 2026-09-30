import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/providers/currency_provider.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/repositories/app_repository.dart';
import '../../shared/widgets/main_shell.dart';
import '../../shared/widgets/shared_widgets.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String _period = 'this_week_sat_fri';

  (DateTime, DateTime) _getDateRange(String period) {
    final now = DateTime.now();
    if (period == 'today_daily') {
      final start = DateTime(now.year, now.month, now.day);
      final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
      return (start, end);
    } else if (period == 'this_week_sat_fri') {
      final daysToSub = (now.weekday - DateTime.saturday) % 7;
      final start = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: daysToSub));
      final end = start.add(
        const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
      );
      return (start, end);
    } else if (period == 'this_month') {
      final start = DateTime(now.year, now.month, 1);
      final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      return (start, end);
    } else {
      final start = DateTime(now.year, 1, 1);
      final end = DateTime(now.year, 12, 31, 23, 59, 59);
      return (start, end);
    }
  }

  @override
  Widget build(BuildContext context) {
    final billsAsync = ref.watch(allBillsStreamProvider);
    final workerPaymentsAsync = ref.watch(allWorkerPaymentsStreamProvider);
    final (rangeStart, rangeEnd) = _getDateRange(_period);

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppNavigationDrawer(currentLocation: '/reports'),
      appBar: AppHeader(title: context.translate('reports_analytics')),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.containerMargin),
        children: [
          // Period selector
          _PeriodSelector(
            selected: _period,
            onChanged: (v) => setState(() => _period = v),
          ),
          const SizedBox(height: AppDimensions.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '${context.translate('range')}: ${DateFormat('MMM d, yyyy').format(rangeStart)} - ${DateFormat('MMM d, yyyy').format(rangeEnd)}',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.lg),

          // Real Data Stream
          billsAsync.when(
            data: (allBills) {
              final rangeBills = allBills.where((b) {
                return b.issueDate.isAfter(
                      rangeStart.subtract(const Duration(seconds: 1)),
                    ) &&
                    b.issueDate.isBefore(
                      rangeEnd.add(const Duration(seconds: 1)),
                    );
              }).toList();
              final customerBills = customerBillsOnly(rangeBills).toList();
              final customBills = customBillsOnly(rangeBills).toList();

              final totalRevenue = netRevenue(rangeBills);
              final totalUnpaid = customerBills.fold(
                0.0,
                (sum, b) => sum + b.remainingAmount,
              );
              final paidCount = customerBills
                  .where((b) => b.status == 'paid')
                  .length;

              // Compute revenue per customer map
              final customerRevenueMap = <String, double>{};
              for (var b in customerBills) {
                customerRevenueMap[b.customerName] =
                    (customerRevenueMap[b.customerName] ?? 0.0) + b.total;
              }

              final customCategoryMap = <String, double>{};
              for (var b in customBills) {
                customCategoryMap[b.customerName] =
                    (customCategoryMap[b.customerName] ?? 0.0) + b.total;
              }
              final customCategoryList = customCategoryMap.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));

              final customerRevenueList = customerRevenueMap.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));

              final maxRev = customerRevenueList.isEmpty
                  ? 1.0
                  : customerRevenueList.first.value;

              // Calculate worker salary costs for the same range
              final allPayments = workerPaymentsAsync.valueOrNull ?? [];
              final rangePayments = allPayments.where((p) {
                return p.date.isAfter(
                      rangeStart.subtract(const Duration(seconds: 1)),
                    ) &&
                    p.date.isBefore(rangeEnd.add(const Duration(seconds: 1)));
              });
              final salaryCost = rangePayments
                  .where((p) => p.type == 'salary')
                  .fold(0.0, (sum, p) => sum + p.amount);
              final loanAdvances = rangePayments
                  .where((p) => p.type == 'loan_advance')
                  .fold(0.0, (sum, p) => sum + p.amount);
              final totalWorkerCost = salaryCost + loanAdvances;
              final netProfit = totalRevenue - totalWorkerCost;

              return Column(
                children: [
                  // Summary cards
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: AppDimensions.md,
                    mainAxisSpacing: AppDimensions.md,
                    childAspectRatio: 1.4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      MetricCard(
                        label: context.translate('total_revenue'),
                        value: CurrencyFormatter.formatSYP(totalRevenue),
                      ),
                      MetricCard(
                        label: context.translate('invoices_issued'),
                        value: '${customerBills.length}',
                        icon: Icons.receipt_long_outlined,
                        iconColor: AppColors.primary,
                        iconBg: AppColors.secondaryContainer,
                      ),
                      MetricCard(
                        label: context.translate('paid_invoices'),
                        value: '$paidCount',
                        icon: Icons.check_circle_outline,
                        iconColor: AppColors.secondary,
                        iconBg: AppColors.surfaceContainer,
                      ),
                      MetricCard(
                        label: context.translate('outstanding'),
                        value: CurrencyFormatter.formatSYP(totalUnpaid),
                      ),
                      MetricCard(
                        label: context.translate('worker_salary_costs'),
                        value: CurrencyFormatter.formatSYP(salaryCost),
                      ),
                      MetricCard(
                        label: context.translate('net_profit_after_staff'),
                        value: CurrencyFormatter.formatSYP(netProfit),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppDimensions.lg),

                  // Revenue Breakdown by Customer
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.translate('revenue_by_customer'),
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.md),
                        if (customerRevenueList.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              context.translate('no_bills_recorded_for_period'),
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                color: AppColors.outline,
                              ),
                            ),
                          ),
                        ...customerRevenueList.map(
                          (entry) => _RevenueBar(
                            label: entry.key,
                            amount: entry.value,
                            max: maxRev <= 0 ? 1.0 : maxRev,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.lg),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.translate('custom_bill_expenses'),
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.md),
                        if (customCategoryList.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              context.translate(
                                'no_custom_bills_recorded_for_period',
                              ),
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                color: AppColors.outline,
                              ),
                            ),
                          ),
                        ...customCategoryList.map(
                          (entry) => _RevenueBar(
                            label: entry.key,
                            amount: entry.value,
                            max: customCategoryList.first.value <= 0
                                ? 1.0
                                : customCategoryList.first.value,
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.lg),

                  // Worker Salary Breakdown
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.engineering_outlined,
                              size: 18,
                              color: AppColors.partial,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              context.translate('worker_salary_costs'),
                              style: GoogleFonts.manrope(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.translate('salary_disbursements_and_loans'),
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: AppColors.outline,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.md),
                        if (totalWorkerCost <= 0)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              context.translate('no_worker_payments'),
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                color: AppColors.outline,
                              ),
                            ),
                          )
                        else ...[
                          _RevenueBar(
                            label: context.translate('salary_paid'),
                            amount: salaryCost,
                            max: totalWorkerCost <= 0 ? 1.0 : totalWorkerCost,
                            color: AppColors.partial,
                          ),
                          if (loanAdvances > 0)
                            _RevenueBar(
                              label: context.translate('loan_advances'),
                              amount: loanAdvances,
                              max: totalWorkerCost <= 0 ? 1.0 : totalWorkerCost,
                              color: AppColors.error,
                            ),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, s) => Text(
              context
                  .translate('error_loading_reports')
                  .replaceAll('{error}', '$err'),
              style: GoogleFonts.manrope(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  const _PeriodSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final periods = [
      'today_daily',
      'this_week_sat_fri',
      'this_month',
      'this_year',
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: periods.map((p) {
          final isSel = selected == p;
          return GestureDetector(
            onTap: () => onChanged(p),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: AppDimensions.sm),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSel
                    ? AppColors.primary
                    : AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                border: Border.all(
                  color: isSel ? AppColors.primary : AppColors.outlineVariant,
                ),
              ),
              child: Text(
                context.translate(p),
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isSel ? Colors.white : AppColors.onSurfaceVariant,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _RevenueBar extends StatelessWidget {
  final String label;
  final double amount;
  final double max;

  final Color color;
  const _RevenueBar({
    required this.label,
    required this.amount,
    required this.max,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  color: AppColors.onSurface,
                ),
              ),
              Text(CurrencyFormatter.formatSYP(amount)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            child: LinearProgressIndicator(
              value: (amount / max).clamp(0.0, 1.0),
              backgroundColor: AppColors.surfaceContainer,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}
