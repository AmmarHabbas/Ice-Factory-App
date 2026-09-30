import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/providers/locale_provider.dart';
import '../../shared/widgets/main_shell.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _autoBackup = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppNavigationDrawer(currentLocation: '/settings'),
      appBar: AppHeader(title: context.translate('settings')),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.containerMargin),
        children: [
          // Profile Card
          _ProfileCard(),

          const SizedBox(height: AppDimensions.lg),

          // General Settings
          _SettingsGroup(
            title: context.translate('general'),
            children: [
              _SettingsTile(
                icon: Icons.language_outlined,
                label: context.translate('language'),
                trailing: _DropdownSetting(
                  value: locale.languageCode == 'ar' ? 'العربية' : 'English',
                  options: const ['English', 'العربية'],
                  onChanged: (value) => ref
                      .read(localeProvider.notifier)
                      .setLocale(Locale(value == 'العربية' ? 'ar' : 'en')),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.md),

          // Notifications
          _SettingsGroup(
            title: context.translate('notifications'),
            children: [
              _SwitchTile(
                icon: Icons.notifications_outlined,
                label: context.translate('enable_notifications'),
                subtitle: context.translate('daily_reminders'),
                value: _notificationsEnabled,
                onChanged: (v) => setState(() => _notificationsEnabled = v),
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.md),

          // Data & Backup
          _SettingsGroup(
            title: context.translate('data_backup'),
            children: [
              _SwitchTile(
                icon: Icons.backup_outlined,
                label: context.translate('auto_backup'),
                subtitle: context.translate('backup_daily'),
                value: _autoBackup,
                onChanged: (v) => setState(() => _autoBackup = v),
              ),
              _SettingsTile(
                icon: Icons.cloud_upload_outlined,
                label: context.translate('backup_now'),
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.translate('backup_created'))),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.md),
          // About
          _SettingsGroup(
            title: context.translate('about'),
            children: [
              _SettingsTile(
                icon: Icons.info_outline,
                label: context.translate('app_version'),
                trailing: Text(
                  'v1.0.0',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 13,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.xl),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: const Icon(Icons.person, size: 32, color: Colors.white),
          ),
          const SizedBox(width: AppDimensions.lg),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Fawares Al Sham',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                context.translate('admin_account'),
                style: GoogleFonts.manrope(fontSize: 13, color: Colors.white70),
              ),
              Text(
                context.translate('ice_factory_management'),
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  color: Colors.white54,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SettingsGroup({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: AppDimensions.sm),
          child: Text(
            title,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03))],
          ),
          child: Column(
            children: children.asMap().entries.map((e) {
              return Column(
                children: [
                  e.value,
                  if (e.key < children.length - 1)
                    const Divider(
                      height: 1,
                      indent: 56,
                      color: AppColors.outlineVariant,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.lg,
        vertical: 2,
      ),
      leading: Icon(icon, color: AppColors.secondary, size: 22),
      title: Text(
        label,
        style: GoogleFonts.manrope(fontSize: 14, color: AppColors.onSurface),
      ),
      trailing:
          trailing ??
          (onTap != null
              ? const Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: AppColors.outline,
                )
              : null),
      onTap: onTap,
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SwitchTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.lg,
        vertical: 2,
      ),
      leading: Icon(icon, color: AppColors.secondary, size: 22),
      title: Text(
        label,
        style: GoogleFonts.manrope(fontSize: 14, color: AppColors.onSurface),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.manrope(
          fontSize: 11,
          color: AppColors.onSurfaceVariant,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.primary,
      ),
    );
  }
}

class _DropdownSetting extends StatelessWidget {
  final String value;
  final List<String> options;
  final ValueChanged<String?> onChanged;
  const _DropdownSetting({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: value,
      underline: const SizedBox(),
      items: options
          .map(
            (o) => DropdownMenuItem(
              value: o,
              child: Text(o, style: GoogleFonts.manrope(fontSize: 13)),
            ),
          )
          .toList(),
      onChanged: (v) {
        if (v != null) {
          onChanged(v);
        }
      },
      style: GoogleFonts.manrope(fontSize: 13, color: AppColors.primary),
      icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
    );
  }
}
