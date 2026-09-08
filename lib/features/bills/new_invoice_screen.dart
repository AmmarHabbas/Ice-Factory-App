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

const List<String> kStandardIceProducts = [
  '1 kg ice bag',
  '5 kgs ice bundle',
  '5kgs ice bag',
];

class _InvoiceLineItem {
  String name;
  int quantity;
  double unitPrice;
  _InvoiceLineItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
  });
  double get total => quantity * unitPrice;
}

class NewInvoiceScreen extends ConsumerStatefulWidget {
  const NewInvoiceScreen({super.key});

  @override
  ConsumerState<NewInvoiceScreen> createState() => _NewInvoiceScreenState();
}

class _NewInvoiceScreenState extends ConsumerState<NewInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customerCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _paymentStatus = 'unpaid';
  bool _isCustomBill = false;

  final List<_InvoiceLineItem> _items = [
    _InvoiceLineItem(name: '1 kg ice bag', quantity: 10, unitPrice: 10.0),
  ];

  double get _subtotal => _items.fold(0.0, (s, i) => s + i.total);
  double get _tax => 0.0;
  double get _total => _subtotal;

  @override
  Widget build(BuildContext context) {
    final exchangeRate = ref.watch(exchangeRateProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppHeader(
        title: _isCustomBill ? 'New Custom Bill' : 'New Ice Bill',
        showMenuButton: false,
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(
              'Save',
              style: GoogleFonts.manrope(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppDimensions.containerMargin),
          children: [
            // Bill Type Selector (Ice Bill vs Custom Bill)
            Container(
              padding: const EdgeInsets.all(AppDimensions.sm),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _isCustomBill = false;
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !_isCustomBill
                              ? AppColors.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusMedium,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.ac_unit,
                              size: 18,
                              color: !_isCustomBill
                                  ? Colors.white
                                  : AppColors.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Ice Cube Bill',
                              style: GoogleFonts.manrope(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: !_isCustomBill
                                    ? Colors.white
                                    : AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _isCustomBill = true;
                        if (_items.isEmpty) {
                          _items.add(
                            _InvoiceLineItem(
                              name: 'Custom Product / Service',
                              quantity: 1,
                              unitPrice: 50.0,
                            ),
                          );
                        }
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _isCustomBill
                              ? AppColors.secondary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusMedium,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.style,
                              size: 18,
                              color: _isCustomBill
                                  ? Colors.white
                                  : AppColors.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Custom Bill',
                              style: GoogleFonts.manrope(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _isCustomBill
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

            const SizedBox(height: AppDimensions.md),

            // Customer Info
            _SectionCard(
              title: 'Customer',
              child: Column(
                children: [
                  _AppTextField(
                    controller: _customerCtrl,
                    label: 'Customer Name',
                    icon: Icons.person_outline,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: AppDimensions.md),
                  _AppTextField(
                    controller: _addressCtrl,
                    label: 'Delivery Address',
                    icon: Icons.location_on_outlined,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.md),

            // Items
            _SectionCard(
              title: _isCustomBill ? 'Custom Items' : 'Ice Products',
              action: TextButton.icon(
                onPressed: () => setState(
                  () => _items.add(
                    _InvoiceLineItem(
                      name: _isCustomBill
                          ? 'Custom Item'
                          : kStandardIceProducts.first,
                      quantity: 1,
                      unitPrice: 10.0,
                    ),
                  ),
                ),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Item'),
              ),
              child: Column(
                children: [
                  ..._items.asMap().entries.map(
                    (entry) => _LineItemRow(
                      item: entry.value,
                      index: entry.key,
                      isCustom: _isCustomBill,
                      onDelete: _items.length > 1
                          ? () => setState(() => _items.removeAt(entry.key))
                          : null,
                      onChanged: () => setState(() {}),
                    ),
                  ),
                  const Divider(color: AppColors.outlineVariant),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'TOTAL',
                        style: GoogleFonts.jetBrainsMono(
                          fontWeight: FontWeight.bold,
                          color: AppColors.onSurface,
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            CurrencyFormatter.formatUSD(_total),
                            style: GoogleFonts.manrope(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            CurrencyFormatter.formatSYP(_total, exchangeRate),
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.secondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.md),

            // Payment Status
            _SectionCard(
              title: 'Payment',
              child: Column(
                children: [
                  _PaymentStatusButton(
                    label: 'Unpaid',
                    value: 'unpaid',
                    selected: _paymentStatus,
                    color: AppColors.unpaid,
                    onTap: () => setState(() => _paymentStatus = 'unpaid'),
                  ),
                  const SizedBox(height: AppDimensions.sm),
                  _PaymentStatusButton(
                    label: 'Partial',
                    value: 'partial',
                    selected: _paymentStatus,
                    color: AppColors.partial,
                    onTap: () => setState(() => _paymentStatus = 'partial'),
                  ),
                  const SizedBox(height: AppDimensions.sm),
                  _PaymentStatusButton(
                    label: 'Paid',
                    value: 'paid',
                    selected: _paymentStatus,
                    color: AppColors.paid,
                    onTap: () => setState(() => _paymentStatus = 'paid'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.md),

            // Notes
            _SectionCard(
              title: 'Notes',
              child: _AppTextField(
                controller: _notesCtrl,
                label: 'Optional notes',
                icon: Icons.notes,
                maxLines: 3,
              ),
            ),
            const SizedBox(height: AppDimensions.xl),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _save,
                child: Text(
                  'Create Invoice',
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      final billId =
          'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      final customerName = _customerCtrl.text.trim();
      final paidAmount = _paymentStatus == 'paid'
          ? _total
          : (_paymentStatus == 'partial' ? _total * 0.5 : 0.0);
      final remaining = _total - paidAmount;

      final bill = Bill(
        id: billId,
        customerId: 'CUST-${customerName.hashCode.abs()}',
        customerName: customerName,
        issueDate: DateTime.now(),
        dueDate: DateTime.now().add(const Duration(days: 14)),
        status: _paymentStatus,
        subtotal: _subtotal,
        tax: _tax,
        total: _total,
        paidAmount: paidAmount,
        remainingAmount: remaining,
        notes: _notesCtrl.text.isEmpty ? null : _notesCtrl.text,
        isCustom: _isCustomBill,
      );

      final itemsCompanions = _items.map((i) {
        return BillItemsCompanion.insert(
          billId: billId,
          productName: i.name.isEmpty ? 'Item' : i.name,
          unitSize: 'unit',
          quantity: i.quantity,
          unitPrice: i.unitPrice,
          totalPrice: i.total,
        );
      }).toList();

      await ref.read(billRepositoryProvider).createBill(bill, itemsCompanions);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isCustomBill
                  ? 'Custom Bill $billId Created!'
                  : 'Ice Cube Bill $billId Created!',
            ),
          ),
        );
        context.go('/bills');
      }
    }
  }

  @override
  void dispose() {
    _customerCtrl.dispose();
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget? action;
  final Widget child;
  const _SectionCard({required this.title, this.action, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
              if (action != null) action!,
            ],
          ),
          const SizedBox(height: AppDimensions.md),
          child,
        ],
      ),
    );
  }
}

class _LineItemRow extends StatelessWidget {
  final _InvoiceLineItem item;
  final int index;
  final bool isCustom;
  final VoidCallback? onDelete;
  final VoidCallback onChanged;
  const _LineItemRow({
    required this.item,
    required this.index,
    required this.isCustom,
    this.onDelete,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.sm),
      padding: const EdgeInsets.all(AppDimensions.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: isCustom
                    ? TextFormField(
                        initialValue: item.name,
                        onChanged: (v) {
                          item.name = v;
                          onChanged();
                        },
                        decoration: const InputDecoration(
                          hintText: 'Custom item name',
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        style: GoogleFonts.manrope(fontSize: 13),
                      )
                    : DropdownButton<String>(
                        value: kStandardIceProducts.contains(item.name)
                            ? item.name
                            : kStandardIceProducts.first,
                        isDense: true,
                        underline: const SizedBox(),
                        items: kStandardIceProducts
                            .map(
                              (p) => DropdownMenuItem(
                                value: p,
                                child: Text(
                                  p,
                                  style: GoogleFonts.manrope(fontSize: 13),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v != null) {
                            item.name = v;
                            onChanged();
                          }
                        },
                      ),
              ),
              if (onDelete != null)
                GestureDetector(
                  onTap: onDelete,
                  child: const Icon(
                    Icons.close,
                    size: 18,
                    color: AppColors.outline,
                  ),
                ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: item.quantity == 0
                      ? ''
                      : item.quantity.toString(),
                  keyboardType: TextInputType.number,
                  onChanged: (v) {
                    item.quantity = int.tryParse(v) ?? 0;
                    onChanged();
                  },
                  decoration: const InputDecoration(
                    hintText: 'Qty',
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  style: GoogleFonts.jetBrainsMono(fontSize: 13),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  initialValue: item.unitPrice == 0 ? '' : '${item.unitPrice}',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (v) {
                    item.unitPrice = double.tryParse(v) ?? 0.0;
                    onChanged();
                  },
                  decoration: const InputDecoration(
                    hintText: 'Price (\$)',
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  style: GoogleFonts.jetBrainsMono(fontSize: 13),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '= \$${item.total.toStringAsFixed(2)}',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? Function(String?)? validator;
  final int maxLines;
  const _AppTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.validator,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18, color: AppColors.outline),
      ),
    );
  }
}

class _PaymentStatusButton extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final Color color;
  final VoidCallback onTap;
  const _PaymentStatusButton({
    required this.label,
    required this.value,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == value;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(AppDimensions.md),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.12)
              : AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          border: Border.all(
            color: isSelected ? color : AppColors.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isSelected ? color : AppColors.outline,
              size: 20,
            ),
            const SizedBox(width: AppDimensions.md),
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? color : AppColors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
