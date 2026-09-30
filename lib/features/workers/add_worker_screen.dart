import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../core/database/app_database.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/providers/repository_providers.dart';
import '../../shared/widgets/main_shell.dart';

class AddWorkerScreen extends ConsumerStatefulWidget {
  const AddWorkerScreen({super.key});

  @override
  ConsumerState<AddWorkerScreen> createState() => _AddWorkerScreenState();
}

class _AddWorkerScreenState extends ConsumerState<AddWorkerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _salaryCtrl = TextEditingController();

  String _selectedRole = 'driver';
  String _selectedShift = 'morning';
  bool _isSaving = false;
  bool _saved = false;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _salaryCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);

    final worker = Worker(
      id: 'FW-${DateTime.now().millisecondsSinceEpoch}',
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      role: _selectedRole,
      shift: _selectedShift,
      monthlySalary: double.tryParse(_salaryCtrl.text) ?? 0.0,
      loanBalance: 0.0,
      hireDate: DateTime.now(),
      isActive: true,
    );

    await ref.read(workerRepositoryProvider).addWorker(worker);

    if (mounted) {
      setState(() {
        _isSaving = false;
        _saved = true;
      });
      // Small delay so the user sees the success state, then go back
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) context.go('/workers');
    }
  }

  InputDecoration _fieldDecoration(String label) => InputDecoration(
    labelText: label,
    labelStyle: GoogleFonts.manrope(
      fontSize: 13,
      color: AppColors.onSurfaceVariant,
    ),
    filled: true,
    fillColor: AppColors.surfaceContainerLow,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
      borderSide: const BorderSide(color: AppColors.primary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
      borderSide: const BorderSide(color: AppColors.error, width: 1.5),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
      borderSide: const BorderSide(color: AppColors.error, width: 2),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final workerIdentityLabel = context.translate('worker_identity');
    final firstNameLabel = context.translate('first_name');
    final lastNameLabel = context.translate('last_name');
    final phoneLabel = context.translate('contact_phone');
    final requiredLabel = context.translate('required');
    final primaryRoleLabel = context.translate('primary_role');
    final operationalStationLabel = context.translate(
      'factory_operational_station',
    );
    final salaryLabel = context.translate('salary');
    final monthlySalaryLabel = context.translate('monthly_salary_syp');
    final sypLabel = context.translate('syp');

    return MainShell(
      currentLocation: '/addworkers',
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppHeader(
          title: context.translate('add_worker'),
          showMenuButton: false,
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppDimensions.containerMargin),
            children: [
              // ── Progress banner ───────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(AppDimensions.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusMedium,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusSmall,
                        ),
                      ),
                      child: const Icon(
                        Icons.person_add_outlined,
                        color: AppColors.onPrimary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                context.translate('onboarding_checklist'),
                                style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                              Text(
                                context.translate('three_of_four_required'),
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 11,
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusFull,
                            ),
                            child: const LinearProgressIndicator(
                              value: 0.75,
                              minHeight: 6,
                              backgroundColor:
                                  AppColors.surfaceContainerHighest,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.secondary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            context.translate('fill_identity_credentials'),
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.xl),

              // ── 1. Worker Identity ─────────────────────────────────────
              _SectionCard(
                icon: Icons.badge_outlined,
                title: '1. $workerIdentityLabel',
                subtitle: context.translate(
                  'legal_factory_identification_data',
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _firstNameCtrl,
                            decoration: _fieldDecoration('$firstNameLabel *'),
                            style: GoogleFonts.manrope(
                              color: AppColors.onSurface,
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Required'
                                : null,
                          ),
                        ),
                        const SizedBox(width: AppDimensions.md),
                        Expanded(
                          child: TextFormField(
                            controller: _lastNameCtrl,
                            decoration: _fieldDecoration('$lastNameLabel *'),
                            style: GoogleFonts.manrope(
                              color: AppColors.onSurface,
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Required'
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.md),
                    TextFormField(
                      controller: _phoneCtrl,
                      decoration: _fieldDecoration('$phoneLabel *'),
                      keyboardType: TextInputType.phone,
                      style: GoogleFonts.manrope(color: AppColors.onSurface),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? context.translate('required')
                          : null,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.xl),

              // ── 2. Primary Role ────────────────────────────────────────
              _SectionCard(
                icon: Icons.engineering_outlined,
                title: primaryRoleLabel,
                subtitle: operationalStationLabel,
                trailingBadge: requiredLabel,
                child: Column(
                  children: [
                    _RoleCard(
                      icon: Icons.local_shipping_outlined,
                      title: context.translate('driver'),
                      subtitle: context.translate(
                        'refrigerated_fleet_distribution_and_logistics',
                      ),
                      value: 'driver',
                      selected: _selectedRole,
                      onTap: () => setState(() => _selectedRole = 'driver'),
                    ),
                    const SizedBox(height: AppDimensions.sm),
                    _RoleCard(
                      icon: Icons.handyman_outlined,
                      title: context.translate('all_around_worker'),
                      subtitle: context.translate(
                        'maintenance_packing_and_flexible_staging',
                      ),
                      value: 'all_around',
                      selected: _selectedRole,
                      onTap: () => setState(() => _selectedRole = 'all_around'),
                    ),
                    const SizedBox(height: AppDimensions.sm),
                    _RoleCard(
                      icon: Icons.ac_unit_outlined,
                      title: context.translate('factory_worker'),
                      subtitle: context.translate(
                        'ice_line_production_and_sub_zero_storage_handling',
                      ),
                      value: 'factory',
                      selected: _selectedRole,
                      onTap: () => setState(() => _selectedRole = 'factory'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.xl),

              // ── 3. Assigned Shift ──────────────────────────────────────
              _SectionCard(
                icon: Icons.schedule_outlined,
                title: context.translate('assigned_shift'),
                subtitle: context.translate('production_line_schedule_blocks'),
                child: Column(
                  children: [
                    _ShiftCard(
                      icon: Icons.wb_sunny_outlined,
                      title: context.translate('morning_shift_title'),
                      subtitle: context.translate('morning_shift'),
                      value: 'morning',
                      selected: _selectedShift,
                      onTap: () => setState(() => _selectedShift = 'morning'),
                    ),
                    const SizedBox(height: AppDimensions.sm),
                    _ShiftCard(
                      icon: Icons.wb_twilight_outlined,
                      title: context.translate('afternoon_shift_title'),
                      subtitle: context.translate('afternoon_shift'),
                      value: 'afternoon',
                      selected: _selectedShift,
                      onTap: () => setState(() => _selectedShift = 'afternoon'),
                    ),
                    const SizedBox(height: AppDimensions.sm),
                    _ShiftCard(
                      icon: Icons.bedtime_outlined,
                      title: context.translate('night_shift_title'),
                      subtitle: context.translate('night_shift'),
                      value: 'night',
                      selected: _selectedShift,
                      onTap: () => setState(() => _selectedShift = 'night'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.xl),

              // ── 4. Compensation & Salary ───────────────────────────────
              _SectionCard(
                icon: Icons.payments_outlined,
                title: salaryLabel,
                subtitle: context.translate('monthly_base_salary_syp'),
                child: TextFormField(
                  controller: _salaryCtrl,
                  decoration: _fieldDecoration(monthlySalaryLabel).copyWith(
                    prefixText: '$sypLabel ',
                    prefixStyle: GoogleFonts.jetBrainsMono(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: GoogleFonts.manrope(color: AppColors.onSurface),
                ),
              ),

              const SizedBox(height: AppDimensions.xl),

              // ── Success banner ─────────────────────────────────────────
              if (_saved)
                Container(
                  padding: const EdgeInsets.all(AppDimensions.md),
                  margin: const EdgeInsets.only(bottom: AppDimensions.md),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryContainer,
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusSmall,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        color: AppColors.paid,
                        size: 24,
                      ),
                      const SizedBox(width: AppDimensions.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.translate('Registration_Successful'),
                              style: GoogleFonts.manrope(
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                            Text(
                              context.translate('Worker_Profile_Initialized'),
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              // ── Submit button ──────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _saved
                        ? AppColors.secondary
                        : AppColors.primaryContainer,
                    foregroundColor: AppColors.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusSmall,
                      ),
                    ),
                    elevation: 2,
                  ),
                  onPressed: _isSaving || _saved ? null : _save,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.onPrimary,
                          ),
                        )
                      : Icon(
                          _saved ? Icons.check : Icons.how_to_reg_outlined,
                          size: 22,
                        ),
                  label: Text(
                    _isSaving
                        ? context.translate('Registering_Worker')
                        : _saved
                        ? context.translate('Worker_Saved')
                        : context.translate('Save_&_Register_Worker'),
                    style: GoogleFonts.manrope(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppDimensions.sm),

              // Cancel
              SizedBox(
                width: double.infinity,
                height: 46,
                child: TextButton(
                  onPressed: () => context.go('/workers'),
                  child: Text(
                    context.translate('cancel'),
                    style: GoogleFonts.manrope(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppDimensions.xl),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? trailingBadge;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailingBadge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer,
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusSmall,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: AppColors.onSecondaryContainer,
                ),
              ),
              const SizedBox(width: AppDimensions.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: AppColors.outline,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailingBadge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusSmall,
                    ),
                  ),
                  child: Text(
                    trailingBadge!,
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppDimensions.md),
          child,
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String value;
  final String selected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
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
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(AppDimensions.md),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primaryContainer
              : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.onPrimary.withValues(alpha: 0.15)
                    : AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
              ),
              child: Icon(
                icon,
                size: 26,
                color: isActive ? AppColors.onPrimary : AppColors.primary,
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isActive
                              ? AppColors.onPrimary
                              : AppColors.primary,
                        ),
                      ),
                      if (isActive) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'ACTIVE',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSecondary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: isActive
                          ? AppColors.onPrimary.withValues(alpha: 0.7)
                          : AppColors.outline,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.onPrimary
                    : AppColors.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check,
                size: 14,
                color: isActive
                    ? AppColors.primaryContainer
                    : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShiftCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String value;
  final String selected;
  final VoidCallback onTap;

  const _ShiftCard({
    required this.icon,
    required this.title,
    required this.subtitle,
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
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(AppDimensions.md),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.secondaryContainer
              : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.secondary.withValues(alpha: 0.1),
                    blurRadius: 6,
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.onSecondaryContainer.withValues(alpha: 0.12)
                    : AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
              ),
              child: Icon(
                icon,
                size: 22,
                color: isActive
                    ? AppColors.onSecondaryContainer
                    : AppColors.secondary,
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isActive
                          ? AppColors.onSecondaryContainer
                          : AppColors.primary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: isActive
                          ? AppColors.onSecondaryContainer.withValues(
                              alpha: 0.7,
                            )
                          : AppColors.outline,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isActive
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 24,
              color: isActive ? AppColors.primary : AppColors.outline,
            ),
          ],
        ),
      ),
    );
  }
}
