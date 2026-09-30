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

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  String _period = 'weekly';

  (DateTime, DateTime) _getDateRange(String period) {
    final now = DateTime.now();
    if (period == 'weekly') {
      // Week starts Saturday, ends Friday
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
    } else if (period == 'monthly') {
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
    final topCustomersAsync = ref.watch(topCustomersStreamProvider);
    final billsAsync = ref.watch(allBillsStreamProvider);
    final workerPaymentsAsync = ref.watch(allWorkerPaymentsStreamProvider);

    final (rangeStart, rangeEnd) = _getDateRange(_period);

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppNavigationDrawer(currentLocation: '/statistics'),
      appBar: AppHeader(title: context.translate('statistics')),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.containerMargin),
        children: [
          // Period tabs (Weekly: Sat-Fri, Monthly, Yearly)
          _PeriodTabs(
            selected: _period,
            onChanged: (v) => setState(() => _period = v),
          ),
          const SizedBox(height: AppDimensions.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '${context.translate('range')}: ${DateFormat('MMM d').format(rangeStart)} - ${DateFormat('MMM d, yyyy').format(rangeEnd)}',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.md),

          // Stream Content
          billsAsync.when(
            data: (billsList) {
              final rangeBills = billsList.where((b) {
                return b.issueDate.isAfter(
                      rangeStart.subtract(const Duration(seconds: 1)),
                    ) &&
                    b.issueDate.isBefore(
                      rangeEnd.add(const Duration(seconds: 1)),
                    );
              }).toList();
              final customerBills = customerBillsOnly(rangeBills).toList();

              final periodRevenue = netRevenue(rangeBills);
              final paidCount = customerBills
                  .where((b) => b.status == 'paid')
                  .length;
              final totalCount = customerBills.length;
              final collectionRate = totalCount == 0
                  ? 0.0
                  : (paidCount / totalCount);

              final rangePayments = (workerPaymentsAsync.valueOrNull ?? [])
                  .where(
                    (p) =>
                        p.date.isAfter(
                          rangeStart.subtract(const Duration(seconds: 1)),
                        ) &&
                        p.date.isBefore(
                          rangeEnd.add(const Duration(seconds: 1)),
                        ),
                  )
                  .toList();
              final salaryCost = rangePayments
                  .where((p) => p.type == 'salary')
                  .fold(0.0, (sum, p) => sum + p.amount);

              return Column(
                children: [
                  // KPI Summary
                  _KpiSummary(
                    periodRevenue: periodRevenue,
                    totalCount: totalCount,
                    salaryCost: salaryCost,
                  ),

                  const SizedBox(height: AppDimensions.lg),

                  // Performance Metrics
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.translate('performance_metrics'),
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.md),
                        _PerformanceMetric(
                          label: context.translate('invoice_collection_rate'),
                          value: collectionRate,
                          displayValue:
                              '${(collectionRate * 100).toStringAsFixed(0)}%',
                          color: AppColors.primary,
                        ),
                        _PerformanceMetric(
                          label: context.translate('total_orders_completed'),
                          value: totalCount == 0 ? 0.0 : 1.0,
                          displayValue:
                              '$totalCount ${context.translate('orders')}',
                          color: AppColors.secondary,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, s) => Text(
              context
                  .translate('error_loading_stats')
                  .replaceAll('{error}', '$err'),
              style: GoogleFonts.manrope(color: AppColors.error),
            ),
          ),

          const SizedBox(height: AppDimensions.md),

          // Real-time Top Customers ranked strictly by order count with rich visual chart
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.translate('top_customers_chart'),
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusFull,
                        ),
                      ),
                      child: Text(
                        context.translate('ranked_by_orders'),
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.sm),
                Text(
                  context.translate('customers_ranked_desc'),
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppDimensions.md),
                topCustomersAsync.when(
                  data: (topList) {
                    if (topList.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Center(
                          child: Text(
                            context.translate('no_customer_orders_recorded'),
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              color: AppColors.outline,
                            ),
                          ),
                        ),
                      );
                    }

                    final maxOrders = topList.fold<int>(
                      1,
                      (max, c) => c.orderCount > max ? c.orderCount : max,
                    );

                    return Column(
                      children: topList.take(6).toList().asMap().entries.map((
                        e,
                      ) {
                        final rank = e.key + 1;
                        final custObj = e.value;
                        final ratio = (custObj.orderCount / maxOrders).clamp(
                          0.05,
                          1.0,
                        );

                        return _TopCustomerBarRow(
                          rank: rank,
                          name: custObj.customer.name,
                          orderCount: custObj.orderCount,
                          ratio: ratio,
                        );
                      }).toList(),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, s) => Center(
                    child: Text(
                      '${context.translate('error_loading_top_customers')}: $err',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodTabs extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  const _PeriodTabs({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final periods = ['weekly', 'monthly', 'yearly'];
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: Row(
        children: periods.map((p) {
          final isSel = selected == p;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(p),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isSel ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusSmall,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  context.translate(p),
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSel ? Colors.white : AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _KpiSummary extends StatelessWidget {
  final double periodRevenue;
  final int totalCount;
  final double salaryCost;

  const _KpiSummary({
    required this.periodRevenue,
    required this.totalCount,
    required this.salaryCost,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _KpiCard(
            label: context.translate('total_revenue'),
            value: CurrencyFormatter.formatSYP(periodRevenue),
          ),
        ),
        const SizedBox(width: AppDimensions.sm),
        Expanded(
          child: _KpiCard(
            label: context.translate('salary'),
            value: CurrencyFormatter.formatSYP(salaryCost),
          ),
        ),
        const SizedBox(width: AppDimensions.sm),
        Expanded(
          child: _KpiCard(
            label: context.translate('total_orders'),
            value: '$totalCount',
            subValue: context.translate('invoice'),
          ),
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String? subValue;
  const _KpiCard({required this.label, required this.value, this.subValue});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 9,
              color: AppColors.onSurfaceVariant,
            ),
            maxLines: 1,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          if (subValue != null) ...[
            const SizedBox(height: 2),
            Text(
              subValue!,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 9,
                color: AppColors.secondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PerformanceMetric extends StatelessWidget {
  final String label;
  final double value;
  final String displayValue;
  final Color color;
  const _PerformanceMetric({
    required this.label,
    required this.value,
    required this.displayValue,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.md),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 13,
                color: AppColors.onSurface,
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.md),
          SizedBox(
            width: 100,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              child: LinearProgressIndicator(
                value: value.clamp(0.0, 1.0),
                backgroundColor: AppColors.surfaceContainer,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.sm),
          SizedBox(
            width: 50,
            child: Text(
              displayValue,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopCustomerBarRow extends StatelessWidget {
  final int rank;
  final String name;
  final int orderCount;
  final double ratio;

  const _TopCustomerBarRow({
    required this.rank,
    required this.name,
    required this.orderCount,
    required this.ratio,
  });

  @override
  Widget build(BuildContext context) {
    final rankColor = rank == 1
        ? const Color(0xFFFFB800)
        : rank == 2
        ? const Color(0xFF94A3B8)
        : rank == 3
        ? const Color(0xFFCD7F32)
        : AppColors.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: rankColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$rank',
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: rankColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusSmall,
                  ),
                ),
                child: Text(
                  "$orderCount ${context.translate(orderCount == 1 || orderCount == 0 ? 'order' : 'orders')}",
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Horizontal progress bar representing order volume
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: AppColors.surfaceContainer,
              valueColor: AlwaysStoppedAnimation<Color>(
                rank == 1
                    ? AppColors.primary
                    : (rank <= 3 ? AppColors.secondary : AppColors.outline),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
