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

class CustomerDirectoryScreen extends ConsumerStatefulWidget {
  const CustomerDirectoryScreen({super.key});

  @override
  ConsumerState<CustomerDirectoryScreen> createState() =>
      _CustomerDirectoryScreenState();
}

class _CustomerDirectoryScreenState
    extends ConsumerState<CustomerDirectoryScreen> {
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
    final customersAsync = ref.watch(allCustomersStreamProvider);
    final exchangeRate = ref.watch(exchangeRateProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppNavigationDrawer(currentLocation: '/customers'),
      appBar: AppHeader(
        title: 'Customer Directory',
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.primary),
            onPressed: () => context.go('/customers/add'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppDimensions.containerMargin,
                AppDimensions.md,
                AppDimensions.containerMargin,
                AppDimensions.sm),
            child: AppSearchBar(
              hint: 'Search by name, phone, or address...',
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          FilterChipRow(
            chips: const ['All', 'With Debt', 'Active', 'New'],
            selected: _filter,
            onSelected: (v) => setState(() => _filter = v),
          ),
          const SizedBox(height: AppDimensions.md),
          Expanded(
            child: customersAsync.when(
              data: (customersList) {
                final filtered = customersList.where((c) {
                  final matchCat = switch (_filter) {
                    'With Debt' => c.outstandingBalance > 0,
                    'Active' => c.category == 'active',
                    'New' => c.category == 'new',
                    _ => true,
                  };
                  final matchQ = _query.isEmpty ||
                      c.name.toLowerCase().contains(_query.toLowerCase()) ||
                      c.phone.toLowerCase().contains(_query.toLowerCase()) ||
                      c.address.toLowerCase().contains(_query.toLowerCase());
                  return matchCat && matchQ;
                }).toList();

                if (filtered.isEmpty) {
                  return const EmptyStateWidget(
                    icon: Icons.person_search_outlined,
                    title: 'No Customers Found',
                    subtitle: 'Tap + above to add a new customer',
                  );
                }

                final totalWithDebt = customersList
                    .where((c) => c.outstandingBalance > 0)
                    .length;

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.containerMargin),
                      child: Row(
                        children: [
                          _StatMiniCard(
                            title: 'Total Customers',
                            value: '${customersList.length}',
                            icon: Icons.people_outline,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: AppDimensions.md),
                          _StatMiniCard(
                            title: 'With Debt',
                            value: '$totalWithDebt',
                            icon: Icons.warning_amber_rounded,
                            color: AppColors.unpaid,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimensions.md),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.containerMargin),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final customer = filtered[index];
                          return _CustomerCard(
                            customer: customer,
                            exchangeRate: exchangeRate,
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Text('Error loading customers: $err',
                    style: GoogleFonts.manrope(color: AppColors.error)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatMiniCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  const _StatMiniCard(
      {required this.title,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.03), blurRadius: 8)
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: AppDimensions.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.jetBrainsMono(
                        fontSize: 10, color: AppColors.onSurfaceVariant)),
                Text(value,
                    style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurface)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final Customer customer;
  final double exchangeRate;
  const _CustomerCard(
      {required this.customer, required this.exchangeRate});

  @override
  Widget build(BuildContext context) {
    final hasDebt = customer.outstandingBalance > 0;

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
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.md, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: hasDebt
                ? AppColors.unpaidContainer
                : AppColors.secondaryContainer,
            borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          ),
          child: Icon(
            Icons.store_outlined,
            color: hasDebt ? AppColors.unpaid : AppColors.secondary,
            size: 22,
          ),
        ),
        title: Text(customer.name,
            style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(customer.phone,
                style: GoogleFonts.jetBrainsMono(
                    fontSize: 11, color: AppColors.onSurfaceVariant)),
            Text(customer.address,
                style: GoogleFonts.manrope(
                    fontSize: 11, color: AppColors.outline)),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (hasDebt) ...[
              Text(
                CurrencyFormatter.formatUSD(customer.outstandingBalance),
                style: GoogleFonts.jetBrainsMono(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.unpaid),
              ),
              Text(
                'Due Balance',
                style: GoogleFonts.manrope(
                    fontSize: 9, color: AppColors.unpaid),
              ),
            ] else ...[
              Text('Clean',
                  style: GoogleFonts.jetBrainsMono(
                      fontSize: 11, color: AppColors.paid)),
            ],
          ],
        ),
        onTap: () => context.go('/customers/detail', extra: customer),
      ),
    );
  }
}
