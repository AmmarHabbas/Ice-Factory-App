import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../core/database/app_database.dart';
import '../../core/providers/currency_provider.dart';
import '../../core/providers/repository_providers.dart';
import '../../shared/widgets/main_shell.dart';
import '../../shared/widgets/shared_widgets.dart';

class InvoiceDetailScreen extends ConsumerWidget {
  final Bill? bill;
  const InvoiceDetailScreen({super.key, this.bill});

  Future<void> _deleteInvoice(
    BuildContext context,
    WidgetRef ref,
    Bill bill,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Invoice?'),
        content: Text('Invoice ${bill.id} will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(billRepositoryProvider).deleteBill(bill);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Invoice deleted')));
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete invoice: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (bill == null) {
      return Scaffold(
        appBar: AppHeader(title: 'Invoice Detail', showMenuButton: false),
        body: const Center(child: Text('No invoice selected')),
      );
    }

    final b = bill!;
    final exchangeRate = ref.watch(exchangeRateProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppHeader(
        title: b.id,
        showMenuButton: false,
        actions: [
          IconButton(
            onPressed: () => _deleteInvoice(context, ref, b),
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            tooltip: 'Delete invoice',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.containerMargin),
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(AppDimensions.lg),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: b.isCustom
                    ? [AppColors.secondary, AppColors.primary]
                    : [AppColors.primary, AppColors.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      b.id,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    StatusChip(
                      label: b.status.toUpperCase(),
                      color: b.status == 'paid'
                          ? AppColors.paid
                          : (b.status == 'partial'
                                ? AppColors.partial
                                : AppColors.unpaid),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.sm),
                Text(
                  b.customerName,
                  style: GoogleFonts.manrope(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                if (b.isCustom)
                  Text(
                    'Custom Bill',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                const SizedBox(height: AppDimensions.lg),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TOTAL',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 9,
                              color: Colors.white54,
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            CurrencyFormatter.formatUSD(b.total),
                            style: GoogleFonts.manrope(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            CurrencyFormatter.formatSYP(b.total, exchangeRate),
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 10,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PAID',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 9,
                              color: Colors.white54,
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            CurrencyFormatter.formatUSD(b.paidAmount),
                            style: GoogleFonts.manrope(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (b.remainingAmount > 0)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DUE',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 9,
                                color: Colors.white54,
                                letterSpacing: 1,
                              ),
                            ),
                            Text(
                              CurrencyFormatter.formatUSD(b.remainingAmount),
                              style: GoogleFonts.manrope(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFFF6B6B),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: AppDimensions.lg),

          // Invoice Info
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Invoice Details',
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: AppDimensions.md),
                _InfoRow(
                  label: 'Date',
                  value: b.issueDate.toString().substring(0, 10),
                ),
                _InfoRow(label: 'Customer', value: b.customerName),
                _InfoRow(
                  label: 'Type',
                  value: b.isCustom ? 'Custom Bill' : 'Ice Cube Bill',
                ),
                _InfoRow(
                  label: 'Status',
                  valueWidget: StatusChip(
                    label: b.status.toUpperCase(),
                    color: b.status == 'paid'
                        ? AppColors.paid
                        : (b.status == 'partial'
                              ? AppColors.partial
                              : AppColors.unpaid),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppDimensions.md),

          // Items Loaded from DB
          FutureBuilder<List<BillItem>>(
            future: ref.read(billRepositoryProvider).getItemsForBill(b.id),
            builder: (ctx, snapshot) {
              final items = snapshot.data ?? [];
              return AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Items',
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.sm),
                    const Divider(color: AppColors.outlineVariant),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            'ITEM',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 9,
                              color: AppColors.outline,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'QTY',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 9,
                              color: AppColors.outline,
                              letterSpacing: 0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'PRICE',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 9,
                              color: AppColors.outline,
                              letterSpacing: 0.5,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'TOTAL',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 9,
                              color: AppColors.outline,
                              letterSpacing: 0.5,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.sm),
                    if (items.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'No item details recorded',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: AppColors.outline,
                          ),
                        ),
                      ),
                    ...items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                item.productName,
                                style: GoogleFonts.manrope(
                                  fontSize: 13,
                                  color: AppColors.onSurface,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '${item.quantity}',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 13,
                                  color: AppColors.onSurface,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                CurrencyFormatter.formatUSD(item.unitPrice),
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 11,
                                  color: AppColors.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                CurrencyFormatter.formatUSD(item.totalPrice),
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.onSurface,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(color: AppColors.outlineVariant),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'TOTAL',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.onSurface,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.formatUSD(b.total),
                          style: GoogleFonts.manrope(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String? value;
  final Widget? valueWidget;
  const _InfoRow({required this.label, this.value, this.valueWidget});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
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
          if (valueWidget != null) valueWidget!,
          if (value != null)
            Text(
              value!,
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.onSurface,
              ),
            ),
        ],
      ),
    );
  }
}
