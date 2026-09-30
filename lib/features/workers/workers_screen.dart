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
import '../../shared/widgets/main_shell.dart';

class WorkersScreen extends ConsumerStatefulWidget {
  const WorkersScreen({super.key});

  @override
  ConsumerState<WorkersScreen> createState() => _WorkersScreenState();
}

class _WorkersScreenState extends ConsumerState<WorkersScreen> {
  String _filter = 'all';
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Worker> _applyFilter(List<Worker> workers) {
    return workers.where((w) {
      final matchShift = _filter == 'all' || w.shift == _filter;
      final fullName = '${w.firstName} ${w.lastName}'.toLowerCase();
      final matchSearch =
          _searchQuery.isEmpty ||
          fullName.contains(_searchQuery) ||
          w.role.toLowerCase().contains(_searchQuery);
      return matchShift && matchSearch;
    }).toList();
  }

  String _shiftLabel(BuildContext context, String shift) {
    switch (shift) {
      case 'morning':
        return context.translate('morning_shift');
      case 'afternoon':
        return context.translate('afternoon_shift');
      case 'night':
        return context.translate('night_shift');
      default:
        return shift;
    }
  }

  IconData _shiftIcon(String shift) {
    switch (shift) {
      case 'morning':
        return Icons.wb_sunny_outlined;
      case 'afternoon':
        return Icons.wb_twilight_outlined;
      case 'night':
        return Icons.bedtime_outlined;
      default:
        return Icons.schedule_outlined;
    }
  }

  String _roleLabel(BuildContext context, String role) {
    switch (role) {
      case 'driver':
        return context.translate('driver');
      case 'all_around':
        return context.translate('all_around_worker');
      case 'factory':
        return context.translate('factory_worker');
      default:
        return role;
    }
  }

  Future<void> _showPayDialog(BuildContext context, Worker worker) async {
    final amountCtrl = TextEditingController();
    final typeNotifier = ValueNotifier<String>('salary');
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: AppColors.surfaceContainerLowest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          ),
          title: Text(
            '${context.translate('pay')} ${worker.firstName}',
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ValueListenableBuilder<String>(
                valueListenable: typeNotifier,
                builder: (_, type, __) => Column(
                  children: [
                    _PayTypeChip(
                      label: context.translate('salary'),
                      value: 'salary',
                      selected: type,
                      onTap: () {
                        typeNotifier.value = 'salary';
                        setS(() {});
                      },
                    ),
                    const SizedBox(height: 6),
                    _PayTypeChip(
                      label: context.translate('loan_advance'),
                      value: 'loan_advance',
                      selected: type,
                      onTap: () {
                        typeNotifier.value = 'loan_advance';
                        setS(() {});
                      },
                    ),
                    const SizedBox(height: 6),
                    _PayTypeChip(
                      label: context.translate('loan_repayment'),
                      value: 'loan_repayment',
                      selected: type,
                      onTap: () {
                        typeNotifier.value = 'loan_repayment';
                        setS(() {});
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: context.translate('amount_syp'),
                  prefixText: '${context.translate('syp')} ',
                  filled: true,
                  fillColor: AppColors.surfaceContainerLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusSmall,
                    ),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: GoogleFonts.manrope(color: AppColors.onSurface),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                context.translate('cancel'),
                style: GoogleFonts.manrope(color: AppColors.outline),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusSmall,
                  ),
                ),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                context.translate('confirm'),
                style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      final amount = double.tryParse(amountCtrl.text) ?? 0.0;
      if (amount <= 0) return;
      final payment = WorkerPayment(
        id: 'WP-${DateTime.now().millisecondsSinceEpoch}',
        workerId: worker.id,
        type: typeNotifier.value,
        amount: amount,
        date: DateTime.now(),
        notes: null,
      );
      await ref.read(workerRepositoryProvider).addPayment(payment);
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(
            content: Text(
              context
                  .translate('payment_recorded_for')
                  .replaceAll('{name}', worker.firstName),
              style: GoogleFonts.manrope(),
            ),
            backgroundColor: AppColors.paid,
          ),
        );
      });
    }
  }

  Future<void> _confirmDelete(BuildContext context, Worker worker) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
        title: Text(
          context.translate('remove_worker'),
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w700,
            color: AppColors.error,
          ),
        ),
        content: Text(
          context
              .translate('remove_worker_confirmation')
              .replaceAll('{name}', '${worker.firstName} ${worker.lastName}'),
          style: GoogleFonts.manrope(color: AppColors.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              context.translate('cancel'),
              style: GoogleFonts.manrope(color: AppColors.outline),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              context.translate('remove'),
              style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(workerRepositoryProvider).deleteWorker(worker.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final workersAsync = ref.watch(allWorkersStreamProvider);
    final totalLoanAsync = ref.watch(totalLoanBalanceStreamProvider);

    return MainShell(
      currentLocation: '/workers',
      child: Scaffold(
        backgroundColor: AppColors.background,
        drawer: const AppNavigationDrawer(currentLocation: '/workers'),
        appBar: AppHeader(title: context.translate('workers')),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push('/addworkers'),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          icon: const Icon(Icons.person_add_outlined),
          label: Text(
            '+ ${context.translate('add')}',
            style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
          ),
        ),
        body: Column(
          children: [
            // ── Search bar ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.containerMargin,
                AppDimensions.md,
                AppDimensions.containerMargin,
                0,
              ),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: context.translate('search_by_name_or_role'),
                  hintStyle: GoogleFonts.manrope(
                    color: AppColors.outline,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.outline,
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceContainerLowest,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusMedium,
                    ),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // ── Shift filter chips ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.containerMargin,
                vertical: AppDimensions.sm,
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      label: context.translate('all'),
                      active: _filter == 'all',
                      onTap: () => setState(() => _filter = 'all'),
                    ),
                    const SizedBox(width: AppDimensions.xs),
                    _FilterChip(
                      label: context.translate('morning_shift').split(' ')[0],
                      dotColor: AppColors.secondary,
                      active: _filter == 'morning',
                      onTap: () => setState(() => _filter = 'morning'),
                    ),
                    const SizedBox(width: AppDimensions.xs),
                    _FilterChip(
                      label: context.translate('afternoon_shift').split(' ')[0],
                      dotColor: AppColors.secondary,
                      active: _filter == 'afternoon',
                      onTap: () => setState(() => _filter = 'afternoon'),
                    ),
                    const SizedBox(width: AppDimensions.xs),
                    _FilterChip(
                      label: context.translate('night_shift').split(' ')[0],
                      dotColor: AppColors.primary,
                      active: _filter == 'night',
                      onTap: () => setState(() => _filter = 'night'),
                    ),
                  ],
                ),
              ),
            ),

            // ── Metrics strip ────────────────────────────────────────────
            workersAsync.when(
              data: (workers) {
                final displayed = _applyFilter(workers);
                final totalLoan = totalLoanAsync.valueOrNull ?? 0.0;
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.containerMargin,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _MetricStrip(
                          label: context
                              .translate('active_shown')
                              .replaceAll(
                                '{count}',
                                displayed.length.toString(),
                              ),
                          icon: Icons.groups_outlined,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.sm),
                      Expanded(
                        child: _MetricStrip(
                          label:
                              '${context.translate('loans')} ${CurrencyFormatter.formatSYP(totalLoan)}',
                          icon: Icons.account_balance_outlined,
                          color: totalLoan > 0
                              ? AppColors.error
                              : AppColors.paid,
                        ),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            const SizedBox(height: AppDimensions.sm),

            // ── Worker list header ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.containerMargin,
                vertical: AppDimensions.xs,
              ),
              child: Row(
                children: [
                  Text(
                    context.translate('factory_workforce'),
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),

            // ── Workers list ─────────────────────────────────────────────
            Expanded(
              child: workersAsync.when(
                data: (workers) {
                  final displayed = _applyFilter(workers);
                  if (displayed.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.engineering_outlined,
                            size: 64,
                            color: AppColors.outline.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: AppDimensions.md),
                          Text(
                            context.translate('no_workers_found'),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              color: AppColors.outline,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppDimensions.containerMargin,
                      0,
                      AppDimensions.containerMargin,
                      100,
                    ),
                    itemCount: displayed.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppDimensions.md),
                    itemBuilder: (ctx, i) {
                      final worker = displayed[i];
                      return _WorkerCard(
                        worker: worker,
                        shiftLabel: _shiftLabel(context, worker.shift),
                        shiftIcon: _shiftIcon(worker.shift),
                        roleLabel: _roleLabel(context, worker.role),
                        onPay: () => _showPayDialog(context, worker),
                        onDelete: () => _confirmDelete(context, worker),
                        onLoan: () => _showPayDialog(context, worker),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(
                  child: Text(
                    'Error: $err',
                    style: GoogleFonts.manrope(color: AppColors.error),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Supporting widgets ───────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final Color? dotColor;

  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
    this.dotColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dotColor != null && !active) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: active ? AppColors.onPrimary : AppColors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricStrip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? color;

  const _MetricStrip({required this.label, required this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: c),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: c,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkerCard extends StatelessWidget {
  final Worker worker;
  final String shiftLabel;
  final IconData shiftIcon;
  final String roleLabel;
  final VoidCallback onPay;
  final VoidCallback onLoan;
  final VoidCallback onDelete;

  const _WorkerCard({
    required this.worker,
    required this.shiftLabel,
    required this.shiftIcon,
    required this.roleLabel,
    required this.onPay,
    required this.onLoan,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final initials =
        '${worker.firstName[0]}${worker.lastName.isNotEmpty ? worker.lastName[0] : ''}';
    final loanPct = worker.monthlySalary > 0
        ? (worker.loanBalance / worker.monthlySalary).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
        ],
      ),
      padding: const EdgeInsets.all(AppDimensions.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile header
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.secondaryContainer,
                child: Text(
                  initials.toUpperCase(),
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${worker.firstName} ${worker.lastName}',
                      style: GoogleFonts.manrope(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryContainer.withValues(
                          alpha: 0.5,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        roleLabel,
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: Icon(Icons.more_vert, color: AppColors.outline),
                tooltip: context.translate('remove_worker'),
                onLongPress: onDelete,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.sm),

          // Shift banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
            ),
            child: Row(
              children: [
                Icon(shiftIcon, size: 16, color: AppColors.secondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    shiftLabel,
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: worker.isActive
                        ? AppColors.secondaryContainer
                        : AppColors.pendingContainer,
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusFull,
                    ),
                  ),
                  child: Text(
                    worker.isActive
                        ? context.translate('active')
                        : context.translate('inactive'),
                    style: GoogleFonts.manrope(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: worker.isActive
                          ? AppColors.onSecondaryContainer
                          : AppColors.pending,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.sm),

          // Salary info row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.translate('monthly_salary_syp'),
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        color: AppColors.outline,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.formatSYP(worker.monthlySalary),
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
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
                      context.translate('hire_date'),
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        color: AppColors.outline,
                      ),
                    ),
                    Text(
                      DateFormat('MMM d, yyyy').format(worker.hireDate),
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Loan indicator (only if loan > 0)
          if (worker.loanBalance > 0) ...[
            const SizedBox(height: AppDimensions.sm),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.account_balance_outlined,
                            size: 14,
                            color: AppColors.error,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Active Loan',
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${CurrencyFormatter.formatSYP(worker.loanBalance)} Due',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusFull,
                    ),
                    child: LinearProgressIndicator(
                      value: loanPct,
                      minHeight: 6,
                      backgroundColor: AppColors.surfaceContainerHigh,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: AppDimensions.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 14,
                    color: AppColors.paid,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    context.translate('no_loans'),
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    context.translate('zero_dues'),
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.paid,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: AppDimensions.sm),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: _ActionBtn(
                  label: context.translate('pay'),
                  icon: Icons.payments_outlined,
                  color: AppColors.primary,
                  textColor: AppColors.onPrimary,
                  onTap: onPay,
                ),
              ),
              const SizedBox(width: AppDimensions.xs),
              Expanded(
                child: _ActionBtn(
                  label: context.translate('loan_advance'),
                  icon: Icons.credit_score_outlined,
                  color: AppColors.surfaceContainerHigh,
                  textColor: AppColors.primary,
                  onTap: onLoan,
                ),
              ),
              const SizedBox(width: AppDimensions.xs),
              Expanded(
                child: _ActionBtn(
                  label: context.translate('remove'),
                  icon: Icons.delete_outline,
                  color: AppColors.surfaceContainer,
                  textColor: AppColors.error,
                  onTap: onDelete,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: textColor),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PayTypeChip extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final VoidCallback onTap;

  const _PayTypeChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = selected == value;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        ),
        child: Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isActive ? AppColors.onPrimary : AppColors.onSurface,
          ),
        ),
      ),
    );
  }
}
