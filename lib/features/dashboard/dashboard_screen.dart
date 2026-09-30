import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../core/database/app_database.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/providers/currency_provider.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/repositories/app_repository.dart';
import '../../shared/widgets/main_shell.dart';
import '../../shared/widgets/shared_widgets.dart';
import '../schedule/trip_detail_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = DateFormat('EEEE, MMMM d').format(DateTime.now());

    final billsAsync = ref.watch(allBillsStreamProvider);
    final tripsAsync = ref.watch(allTripsStreamProvider);
    final todayIceSoldAsync = ref.watch(todayIceSoldStreamProvider);
    final workerPaymentsAsync = ref.watch(allWorkerPaymentsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppNavigationDrawer(currentLocation: '/dashboard'),
      appBar: AppHeader(title: context.translate('dashboard')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          // ── Greeting Banner ─────────────────────────────────────────────
          _GreetingBanner(today: today),

          // ── Metric Cards 2×2 Grid derived from DB Streams ─────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.containerMargin,
              vertical: AppDimensions.md,
            ),
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: AppDimensions.md,
              mainAxisSpacing: AppDimensions.md,
              childAspectRatio: 1.5,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                billsAsync.when(
                  data: (bills) {
                    final todayStr = DateTime.now().toString().substring(0, 10);
                    final todayBills = bills
                        .where(
                          (b) =>
                              b.issueDate.toString().substring(0, 10) ==
                              todayStr,
                        )
                        .toList();
                    final todayRev = netRevenue(todayBills);

                    // Subtract today's worker costs
                    final allPayments = workerPaymentsAsync.valueOrNull ?? [];
                    final todayPayments = allPayments
                        .where(
                          (p) => p.date.toString().substring(0, 10) == todayStr,
                        )
                        .toList();
                    final salaryCost = todayPayments
                        .where((p) => p.type == 'salary')
                        .fold(0.0, (sum, p) => sum + p.amount);
                    final loanAdvances = todayPayments
                        .where((p) => p.type == 'loan_advance')
                        .fold(0.0, (sum, p) => sum + p.amount);
                    final netTodayRev = todayRev - (salaryCost + loanAdvances);

                    return MetricCard(
                      label: context.translate('todays_revenue'),
                      value: CurrencyFormatter.formatSYP(netTodayRev),
                    );
                  },
                  loading: () => MetricCard(
                    label: context.translate('todays_revenue'),
                    value: '...',
                  ),
                  error: (_, __) => MetricCard(
                    label: context.translate('todays_revenue'),
                    value: '\$0',
                  ),
                ),
                tripsAsync.when(
                  data: (trips) {
                    final todayStr = DateTime.now().toString().substring(0, 10);
                    final todayTrips = trips
                        .where(
                          (t) => t.date.toString().substring(0, 10) == todayStr,
                        )
                        .toList();
                    final completed = todayTrips
                        .where((t) => t.status == 'Completed')
                        .length;
                    return MetricCard(
                      label: context.translate('trips_completed'),
                      value: '$completed',
                      unit: '/ ${todayTrips.length}',
                      icon: Icons.local_shipping_outlined,
                      iconColor: AppColors.primary,
                      iconBg: AppColors.secondaryContainer,
                    );
                  },
                  loading: () => MetricCard(
                    label: context.translate('trips_completed'),
                    value: '...',
                  ),
                  error: (_, __) => MetricCard(
                    label: context.translate('trips_completed'),
                    value: '0',
                  ),
                ),
                billsAsync.when(
                  data: (bills) {
                    final pendingCount = customerBillsOnly(
                      bills,
                    ).where((b) => b.status != 'paid').length;
                    return MetricCard(
                      label: context.translate('pending_bills'),
                      value: '$pendingCount',
                      unit: context.translate('bills'),
                      icon: Icons.pending_actions_outlined,
                      iconColor: AppColors.unpaid,
                      iconBg: AppColors.unpaidContainer,
                    );
                  },
                  loading: () => MetricCard(
                    label: context.translate('pending_bills'),
                    value: '...',
                  ),
                  error: (_, __) => MetricCard(
                    label: context.translate('pending_bills'),
                    value: '0',
                  ),
                ),
                todayIceSoldAsync.when(
                  data: (soldKg) {
                    return MetricCard(
                      label: context.translate('ice_sold'),
                      value: soldKg.toStringAsFixed(0),
                      unit: 'kg',
                      icon: Icons.ac_unit,
                      iconColor: AppColors.secondary,
                      iconBg: AppColors.secondaryContainer.withValues(
                        alpha: 0.3,
                      ),
                    );
                  },
                  loading: () => MetricCard(
                    label: context.translate('ice_sold'),
                    value: '...',
                  ),
                  error: (_, __) => MetricCard(
                    label: context.translate('ice_sold'),
                    value: '0',
                    unit: 'kg',
                  ),
                ),
              ],
            ),
          ),

          // ── Today's Schedule Preview ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.containerMargin,
            ),
            child: SectionHeader(
              title: context.translate('todays_schedule'),
              actionLabel: context.translate('view_all'),
              onAction: () => context.go('/schedule'),
            ),
          ),
          const SizedBox(height: AppDimensions.sm),
          tripsAsync.when(
            data: (trips) {
              final todayStr = DateTime.now().toString().substring(0, 10);
              final todayTrips = trips
                  .where((t) => t.date.toString().substring(0, 10) == todayStr)
                  .toList();
              if (todayTrips.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.containerMargin,
                  ),
                  child: Text(
                    context.translate('No trips scheduled for today'),
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                );
              }
              return Column(
                children: todayTrips
                    .map((trip) => _TripTile(trip: trip))
                    .toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => const SizedBox(),
          ),

          const SizedBox(height: AppDimensions.lg),

          // ── Recent Invoices ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.containerMargin,
            ),
            child: SectionHeader(
              title: context.translate('recent_bills'),
              actionLabel: context.translate('view_all'),
              onAction: () => context.go('/bills'),
            ),
          ),
          const SizedBox(height: AppDimensions.sm),
          billsAsync.when(
            data: (bills) {
              if (bills.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.containerMargin,
                  ),
                  child: Text(
                    'No bills created yet.',
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                );
              }
              return Column(
                children: bills
                    .take(4)
                    .map((inv) => _InvoiceTile(bill: inv))
                    .toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => const SizedBox(),
          ),
        ],
      ),
    );
  }
}

class _GreetingBanner extends StatelessWidget {
  final String today;
  const _GreetingBanner({required this.today});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppDimensions.containerMargin),
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fawares Al Sham 🧊',
                  style: GoogleFonts.manrope(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  today,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: AppDimensions.md),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusFull,
                    ),
                  ),
                  child: Text(
                    'Ice Factory System',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.ac_unit, color: Colors.white, size: 32),
          ),
        ],
      ),
    );
  }
}

class _TripTile extends StatelessWidget {
  final Trip trip;
  const _TripTile({required this.trip});

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (trip.status) {
      'Completed' => AppColors.paid,
      'In Progress' => AppColors.primary,
      _ => AppColors.outline,
    };

    final timeStr = DateFormat('hh:mm').format(trip.date);

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimensions.containerMargin,
        vertical: AppDimensions.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8),
        ],
      ),
      child: ListTile(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TripDetailScreen(trip: trip)),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.md,
          vertical: AppDimensions.xs,
        ),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          ),
          child: Center(
            child: Text(
              timeStr,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
        title: Text(
          trip.truckNumber,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        subtitle: Text(
          '${context.translate('driver')}: ${trip.driverName}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.manrope(
            fontSize: 12,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        trailing: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 90),
          child: StatusChip(label: trip.status, color: statusColor),
        ),
      ),
    );
  }
}

class _InvoiceTile extends StatelessWidget {
  final Bill bill;

  const _InvoiceTile({required this.bill});

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (bill.status) {
      'paid' => AppColors.paid,
      'partial' => AppColors.partial,
      _ => AppColors.unpaid,
    };

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimensions.containerMargin,
        vertical: AppDimensions.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.md,
          vertical: AppDimensions.xs,
        ),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: bill.isCustom
                ? AppColors.secondaryContainer
                : AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          ),
          child: Icon(
            bill.isCustom ? Icons.style : Icons.receipt_long,
            color: bill.isCustom ? AppColors.secondary : AppColors.primary,
            size: 22,
          ),
        ),
        title: Text(
          bill.id,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        subtitle: Text(
          bill.customerName,
          style: GoogleFonts.manrope(
            fontSize: 12,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(CurrencyFormatter.formatSYP(bill.total)),
            const SizedBox(height: 4),
            StatusChip(label: bill.status.toUpperCase(), color: statusColor),
          ],
        ),
        onTap: () => context.push('/bills/detail', extra: bill),
      ),
    );
  }
}
