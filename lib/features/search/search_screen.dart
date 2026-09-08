import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../core/providers/currency_provider.dart';
import '../../core/providers/repository_providers.dart';
import '../../shared/widgets/main_shell.dart';
import '../../shared/widgets/shared_widgets.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _ctrl = TextEditingController();
  String _query = '';
  String _category = 'All';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final billsList = ref.watch(allBillsStreamProvider).value ?? [];
    final customersList = ref.watch(allCustomersStreamProvider).value ?? [];
    final tripsList = ref.watch(allTripsStreamProvider).value ?? [];

    final results = <_SearchResult>[];

    if (_query.isNotEmpty) {
      if (_category == 'All' || _category == 'Invoice') {
        for (var b in billsList) {
          if (b.id.toLowerCase().contains(_query.toLowerCase()) ||
              b.customerName.toLowerCase().contains(_query.toLowerCase())) {
            results.add(_SearchResult(
              type: 'invoice',
              title: b.id,
              subtitle:
                  '${b.customerName} • ${CurrencyFormatter.formatUSD(b.total)} • ${b.status}',
              path: '/bills/detail',
              extra: b,
            ));
          }
        }
      }

      if (_category == 'All' || _category == 'Customer') {
        for (var c in customersList) {
          if (c.name.toLowerCase().contains(_query.toLowerCase()) ||
              c.phone.toLowerCase().contains(_query.toLowerCase()) ||
              c.address.toLowerCase().contains(_query.toLowerCase())) {
            results.add(_SearchResult(
              type: 'customer',
              title: c.name,
              subtitle: '${c.phone} • ${c.address}',
              path: '/customers/detail',
              extra: c,
            ));
          }
        }
      }

      if (_category == 'All' || _category == 'Trip') {
        for (var t in tripsList) {
          if (t.id.toLowerCase().contains(_query.toLowerCase()) ||
              t.truckNumber.toLowerCase().contains(_query.toLowerCase()) ||
              t.driverName.toLowerCase().contains(_query.toLowerCase())) {
            results.add(_SearchResult(
              type: 'trip',
              title: t.truckNumber,
              subtitle: 'Driver: ${t.driverName} • ${t.status}',
              path: '/schedule',
              extra: t,
            ));
          }
        }
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppNavigationDrawer(currentLocation: '/search'),
      appBar: AppHeader(title: 'Search'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppDimensions.containerMargin,
                AppDimensions.md,
                AppDimensions.containerMargin,
                AppDimensions.sm),
            child: AppSearchBar(
                hint: 'Search invoices, customers, trips...',
                controller: _ctrl,
                onChanged: (v) => setState(() => _query = v)),
          ),
          FilterChipRow(
            chips: const ['All', 'Invoice', 'Customer', 'Trip'],
            selected: _category,
            onSelected: (v) => setState(() => _category = v),
          ),
          const SizedBox(height: AppDimensions.md),
          Expanded(
            child: _query.isEmpty
                ? _EmptySearch()
                : results.isEmpty
                    ? const EmptyStateWidget(
                        icon: Icons.search_off,
                        title: 'No Results Found',
                        subtitle: 'Try different keywords or categories')
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.containerMargin),
                        itemCount: results.length,
                        itemBuilder: (ctx, i) =>
                            _ResultTile(result: results[i]),
                      ),
          ),
        ],
      ),
    );
  }
}

class _SearchResult {
  final String type;
  final String title;
  final String subtitle;
  final String path;
  final dynamic extra;
  _SearchResult(
      {required this.type,
      required this.title,
      required this.subtitle,
      required this.path,
      this.extra});
}

IconData _iconForType(String type) {
  return switch (type) {
    'invoice' => Icons.receipt_long_outlined,
    'customer' => Icons.person_outlined,
    'trip' => Icons.local_shipping_outlined,
    _ => Icons.search,
  };
}

class _EmptySearch extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
              color: AppColors.surfaceContainer, shape: BoxShape.circle),
          child: const Icon(Icons.search, size: 36, color: AppColors.outline),
        ),
        const SizedBox(height: AppDimensions.lg),
        Text('Search Everything',
            style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface)),
        const SizedBox(height: AppDimensions.sm),
        Text('Type to search live invoices, customers, trips...',
            style: GoogleFonts.manrope(
                fontSize: 14, color: AppColors.onSurfaceVariant)),
      ],
    );
  }
}

class _ResultTile extends StatelessWidget {
  final _SearchResult result;
  const _ResultTile({required this.result});

  @override
  Widget build(BuildContext context) {
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
              color: AppColors.secondaryContainer,
              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall)),
          child: Icon(_iconForType(result.type),
              color: AppColors.secondary, size: 20),
        ),
        title: Text(result.title,
            style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface)),
        subtitle: Text(result.subtitle,
            style: GoogleFonts.manrope(
                fontSize: 12, color: AppColors.onSurfaceVariant)),
        trailing: const Icon(Icons.chevron_right,
            size: 18, color: AppColors.outline),
        onTap: () => context.go(result.path, extra: result.extra),
      ),
    );
  }
}
