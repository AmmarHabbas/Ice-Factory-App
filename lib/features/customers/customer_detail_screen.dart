import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../core/database/app_database.dart';
import '../../core/providers/currency_provider.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/repositories/app_repository.dart';
import '../../shared/widgets/main_shell.dart';
import '../../shared/widgets/shared_widgets.dart';

class CustomerDetailScreen extends ConsumerStatefulWidget {
  final Customer? customer;
  const CustomerDetailScreen({super.key, this.customer});

  @override
  ConsumerState<CustomerDetailScreen> createState() =>
      _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends ConsumerState<CustomerDetailScreen> {
  String _selectedTab = 'History'; // 'History', 'Payments', 'Notes'

  @override
  Widget build(BuildContext context) {
    if (widget.customer == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: const AppHeader(
          title: 'Customer Detail',
          showMenuButton: false,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.person_off_outlined,
                size: 64,
                color: AppColors.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'No Customer Selected',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => context.pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    final c = widget.customer!;
    final exchangeRate = ref.watch(exchangeRateProvider);
    final allBillsAsync = ref.watch(allBillsStreamProvider);
    final allBillItemsAsync = ref.watch(allBillItemsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppHeader(title: c.name, showMenuButton: false),
      body: allBillsAsync.when(
        data: (allBills) {
          final customerBills = allBills
              .where(
                (b) =>
                    b.customerId == c.id ||
                    b.customerName.toLowerCase() == c.name.toLowerCase(),
              )
              .where((b) => !b.isCustom)
              .toList();
          final totalOrders = customerBills.length;
          final totalPurchasesUSD = customerBills.fold<double>(
            0.0,
            (sum, b) => sum + b.total,
          );
          final totalPaidUSD = customerBills.fold<double>(
            0.0,
            (sum, b) => sum + b.paidAmount,
          );

          // Compute total volume (kg) from bill items
          final customerBillIds = customerBills
              .where((b) => !b.isCustom)
              .map((b) => b.id)
              .toSet();
          final allBillItems = allBillItemsAsync.valueOrNull ?? [];
          final customerItems = allBillItems
              .where((i) => customerBillIds.contains(i.billId))
              .toList();
          double totalVolumeKg = 0.0;
          for (var item in customerItems) {
            totalVolumeKg += calculateBillItemKg(
              item.productName,
              item.quantity,
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.containerMargin,
              AppDimensions.md,
              AppDimensions.containerMargin,
              32,
            ),
            children: [
              // ── Header Profile Card (Stitch MCP Style) ──────────────────
              _buildHeaderProfileCard(context, c),

              const SizedBox(height: AppDimensions.md),

              // ── Key Metrics Grid ──────────────────────────────────────────
              _buildKeyMetricsGrid(
                c,
                exchangeRate,
                totalOrders,
                totalPurchasesUSD,
                totalVolumeKg,
                customerBills,
              ),

              const SizedBox(height: AppDimensions.md),

              // ── Quick Action: Create New Invoice ─────────────────────────
              _buildQuickAction(context, c),

              const SizedBox(height: AppDimensions.lg),

              // ── Tab Navigation (History, Payments, Notes) ────────────────
              _buildTabSelector(),

              const SizedBox(height: AppDimensions.md),

              // ── Tab Content ───────────────────────────────────────────────
              if (_selectedTab == 'History')
                _buildHistoryTab(context, customerBills, exchangeRate)
              else if (_selectedTab == 'Payments')
                _buildPaymentsTab(customerBills, totalPaidUSD, c, exchangeRate)
              else
                _buildNotesTab(c),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error loading customer data: $e')),
      ),
    );
  }

  Widget _buildHeaderProfileCard(BuildContext context, Customer c) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Simulated Map preview banner
          Container(
            height: 90,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryContainer.withValues(alpha: 0.8),
                  AppColors.secondaryContainer.withValues(alpha: 0.9),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -10,
                  bottom: -10,
                  child: Icon(
                    Icons.map_outlined,
                    size: 90,
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              c.shopName.isNotEmpty ? c.shopName : c.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              c.address.isNotEmpty
                                  ? c.address
                                  : 'Commercial District',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.manrope(
                                fontSize: 11,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppDimensions.md),

          // Customer Title & Shop details
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.name,
                      style: GoogleFonts.manrope(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (c.ownerName.isNotEmpty)
                      Text(
                        'Owner: ${c.ownerName}',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            c.address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.storefront,
                  color: AppColors.secondary,
                  size: 26,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.md),

          // Call and Directions action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Calling ${c.name} (${c.phone})...'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.phone, size: 18),
                  label: const Text('Call'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMedium,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Opening navigation to ${c.address}...'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.directions, size: 18),
                  label: const Text('Directions'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.outlineVariant),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMedium,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeyMetricsGrid(
    Customer c,
    double exchangeRate,
    int totalOrders,
    double totalPurchasesUSD,
    double totalVolumeKg,
    List<dynamic> customerBills,
  ) {
    final hasDebt = c.outstandingBalance > 0;
    final lastVisitStr = c.lastVisit != null
        ? DateFormat('MMM d, HH:mm').format(c.lastVisit!)
        : 'Recent';

    return Column(
      children: [
        Row(
          children: [
            // Outstanding Balance Card
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(AppDimensions.md),
                decoration: BoxDecoration(
                  color: hasDebt
                      ? AppColors.unpaidContainer.withValues(alpha: 0.35)
                      : AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusMedium,
                  ),
                  border: Border.all(
                    color: hasDebt
                        ? AppColors.unpaid.withValues(alpha: 0.3)
                        : AppColors.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          hasDebt
                              ? Icons.warning_amber_rounded
                              : Icons.check_circle_outline,
                          size: 14,
                          color: hasDebt ? AppColors.unpaid : AppColors.paid,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'OUTSTANDING',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: hasDebt ? AppColors.unpaid : AppColors.paid,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      CurrencyFormatter.formatUSD(c.outstandingBalance),
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: hasDebt ? AppColors.unpaid : AppColors.onSurface,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.formatSYP(
                        c.outstandingBalance,
                        exchangeRate,
                      ),
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.sm),
            // Total Volume Card
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(AppDimensions.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusMedium,
                  ),
                  border: Border.all(
                    color: AppColors.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.ac_unit,
                          size: 14,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'TOTAL VOLUME',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      totalOrders == 0
                          ? '0 Orders'
                          : '$totalOrders ${totalOrders == 1 ? 'Order' : 'Orders'}',
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    Text(
                      totalVolumeKg > 0
                          ? '${totalVolumeKg.toStringAsFixed(1)} kg total'
                          : CurrencyFormatter.formatUSD(totalPurchasesUSD),
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.sm),
        // Last Visit Full Width Card
        Container(
          padding: const EdgeInsets.all(AppDimensions.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'LAST DELIVERY',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lastVisitStr,
                    style: GoogleFonts.manrope(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusSmall,
                  ),
                ),
                child: Text(
                  'Route 1 (Active)',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAction(BuildContext context, Customer c) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: () => context.go('/bills/create'),
        icon: const Icon(Icons.add_circle, color: AppColors.primary, size: 20),
        label: Text(
          'Create New Invoice',
          style: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.surfaceContainerLowest,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            side: const BorderSide(color: AppColors.outlineVariant, width: 0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildTabSelector() {
    final tabs = ['History', 'Payments', 'Notes'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: Row(
        children: tabs.map((tab) {
          final isSelected = _selectedTab == tab;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = tab),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusSmall,
                  ),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                      ),
                  ],
                ),
                child: Center(
                  child: Text(
                    tab,
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHistoryTab(
    BuildContext context,
    List<Bill> bills,
    double exchangeRate,
  ) {
    if (bills.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: Text(
          'No invoice history found for this customer.',
          style: GoogleFonts.manrope(
            fontSize: 13,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      );
    }

    return Column(
      children: bills.map((bill) {
        final statusColor = switch (bill.status) {
          'paid' => AppColors.paid,
          'partial' => AppColors.partial,
          _ => AppColors.unpaid,
        };

        return Container(
          margin: const EdgeInsets.only(bottom: AppDimensions.sm),
          padding: const EdgeInsets.all(AppDimensions.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    bill.id,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                  ),
                  StatusChip(
                    label: bill.status.toUpperCase(),
                    color: statusColor,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        CurrencyFormatter.formatUSD(bill.total),
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      Text(
                        '${DateFormat('MMM d, yyyy').format(bill.issueDate)} • ${CurrencyFormatter.formatSYP(bill.total, exchangeRate)}',
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () => context.go('/bills/detail', extra: bill),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryContainer.withValues(
                          alpha: 0.25,
                        ),
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusSmall,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.ac_unit,
                            size: 14,
                            color: AppColors.secondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'View Bill',
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPaymentsTab(
    List<Bill> bills,
    double totalPaidUSD,
    Customer c,
    double exchangeRate,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppDimensions.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Payment Summary',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              _DetailRow(
                label: 'Total Collected',
                value: CurrencyFormatter.formatUSD(totalPaidUSD),
                valueColor: AppColors.paid,
              ),
              _DetailRow(
                label: 'Outstanding Balance',
                value: CurrencyFormatter.formatUSD(c.outstandingBalance),
                valueColor: c.outstandingBalance > 0
                    ? AppColors.unpaid
                    : AppColors.paid,
              ),
              _DetailRow(
                label: 'Conversion Rate',
                value: '1 USD = ${exchangeRate.toStringAsFixed(0)} SYP',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.md),
        ...bills.where((b) => b.paidAmount > 0).map((bill) {
          return Container(
            margin: const EdgeInsets.only(bottom: AppDimensions.sm),
            padding: const EdgeInsets.all(AppDimensions.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment on ${bill.id}',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                    Text(
                      DateFormat('MMM d, yyyy').format(bill.issueDate),
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                Text(
                  '+ ${CurrencyFormatter.formatUSD(bill.paidAmount)}',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.paid,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildNotesTab(Customer c) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Customer Notes & Information',
            style: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: AppDimensions.md),
          _DetailRow(label: 'Customer ID', value: c.id),
          _DetailRow(
            label: 'Shop Name',
            value: c.shopName.isNotEmpty ? c.shopName : '-',
          ),
          _DetailRow(
            label: 'Owner Name',
            value: c.ownerName.isNotEmpty ? c.ownerName : '-',
          ),
          _DetailRow(label: 'Phone', value: c.phone),
          _DetailRow(label: 'Address', value: c.address),
          _DetailRow(
            label: 'Account Category',
            value: c.category.toUpperCase(),
          ),
          const SizedBox(height: 8),
          Text(
            'Delivery Guidelines:',
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Standard commercial ice delivery. Morning preferred between 08:00 AM and 11:00 AM.',
            style: GoogleFonts.manrope(fontSize: 12, color: AppColors.outline),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _DetailRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
