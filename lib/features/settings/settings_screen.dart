import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../core/providers/currency_provider.dart';
import '../../shared/widgets/main_shell.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _autoBackup = true;
  String _language = 'English';
  final _rateCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final currentRate = ref.read(exchangeRateProvider);
    _rateCtrl.text = currentRate.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _rateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentRate = ref.watch(exchangeRateProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppNavigationDrawer(currentLocation: '/settings'),
      appBar: AppHeader(title: 'Settings'),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.containerMargin),
        children: [
          // Profile Card
          _ProfileCard(),

          const SizedBox(height: AppDimensions.lg),

          // Currency & Exchange Rate (Locked currency, Admin editable rate)
          _SettingsGroup(
            title: 'Currency & Exchange Rate',
            children: [
              _SettingsTile(
                icon: Icons.currency_exchange,
                label: 'System Currency',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_outline, size: 14, color: AppColors.outline),
                    const SizedBox(width: 4),
                    Text(
                      'USD (\$) / SYP (ل.س)',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.lg, vertical: AppDimensions.sm),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.tune, color: AppColors.secondary, size: 22),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('1 USD Conversion Rate (SYP)',
                                  style: GoogleFonts.manrope(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.onSurface)),
                              Text(
                                'Current active rate: 1 USD = ${currentRate.toStringAsFixed(0)} SYP',
                                style: GoogleFonts.manrope(
                                    fontSize: 12,
                                    color: AppColors.secondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: TextField(
                              controller: _rateCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: '15000',
                                prefixText: '\$ 1 = ',
                                suffixText: 'SYP',
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppDimensions.radiusSmall),
                                ),
                              ),
                              style: GoogleFonts.jetBrainsMono(
                                  fontSize: 14, fontWeight: FontWeight.bold),
                              onSubmitted: (v) {
                                final parsed = double.tryParse(v);
                                if (parsed != null && parsed > 0) {
                                  ref
                                      .read(exchangeRateProvider.notifier)
                                      .updateRate(parsed);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Conversion rate updated to 1 USD = ${parsed.toStringAsFixed(0)} SYP across the entire app.'),
                                      backgroundColor: AppColors.paid,
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          height: 44,
                          child: ElevatedButton(
                            onPressed: () {
                              final parsed = double.tryParse(_rateCtrl.text.trim());
                              if (parsed != null && parsed > 0) {
                                ref
                                    .read(exchangeRateProvider.notifier)
                                    .updateRate(parsed);
                                FocusScope.of(context).unfocus();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Conversion rate updated to 1 USD = ${parsed.toStringAsFixed(0)} SYP across the entire app.'),
                                    backgroundColor: AppColors.paid,
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please enter a valid rate greater than 0'),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusSmall),
                              ),
                            ),
                            child: const Text('Save Rate'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.md),

          // General Settings
          _SettingsGroup(
            title: 'General',
            children: [
              _SettingsTile(
                icon: Icons.language_outlined,
                label: 'Language',
                trailing: _DropdownSetting(
                  value: _language,
                  options: const ['English', 'العربية'],
                  onChanged: (v) => setState(() => _language = v!),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.md),

          // Notifications
          _SettingsGroup(
            title: 'Notifications',
            children: [
              _SwitchTile(
                icon: Icons.notifications_outlined,
                label: 'Enable Notifications',
                subtitle: 'Daily schedule and payment reminders',
                value: _notificationsEnabled,
                onChanged: (v) => setState(() => _notificationsEnabled = v),
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.md),

          // Data & Backup
          _SettingsGroup(
            title: 'Data & Backup',
            children: [
              _SwitchTile(
                icon: Icons.backup_outlined,
                label: 'Auto-Backup',
                subtitle: 'Backup data automatically once a day',
                value: _autoBackup,
                onChanged: (v) => setState(() => _autoBackup = v),
              ),
              _SettingsTile(
                icon: Icons.cloud_upload_outlined,
                label: 'Backup Now',
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Backup created successfully'))),
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.md),

          // About
          _SettingsGroup(
            title: 'About',
            children: [
              _SettingsTile(
                  icon: Icons.info_outline,
                  label: 'App Version',
                  trailing: Text('v1.0.0',
                      style: GoogleFonts.jetBrainsMono(
                          fontSize: 13, color: AppColors.onSurfaceVariant))),
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
            end: Alignment.bottomRight),
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
              Text('Fawares Al Sham',
                  style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
              Text('Admin Account',
                  style: GoogleFonts.manrope(
                      fontSize: 13, color: Colors.white70)),
              Text('Ice Factory Management',
                  style: GoogleFonts.jetBrainsMono(
                      fontSize: 11, color: Colors.white54)),
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
          child: Text(title,
              style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5)),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03), blurRadius: 8)
            ],
          ),
          child: Column(
            children: children.asMap().entries.map((e) {
              return Column(
                children: [
                  e.value,
                  if (e.key < children.length - 1)
                    const Divider(
                        height: 1, indent: 56, color: AppColors.outlineVariant),
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
      contentPadding:
          const EdgeInsets.symmetric(horizontal: AppDimensions.lg, vertical: 2),
      leading: Icon(icon, color: AppColors.secondary, size: 22),
      title: Text(label,
          style: GoogleFonts.manrope(
              fontSize: 14, color: AppColors.onSurface)),
      trailing: trailing ??
          (onTap != null
              ? const Icon(Icons.chevron_right, size: 18, color: AppColors.outline)
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
  const _SwitchTile(
      {required this.icon,
      required this.label,
      required this.subtitle,
      required this.value,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: AppDimensions.lg, vertical: 2),
      leading: Icon(icon, color: AppColors.secondary, size: 22),
      title:
          Text(label, style: GoogleFonts.manrope(fontSize: 14, color: AppColors.onSurface)),
      subtitle: Text(subtitle,
          style: GoogleFonts.manrope(
              fontSize: 11, color: AppColors.onSurfaceVariant)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
      ),
    );
  }
}

class _DropdownSetting extends StatelessWidget {
  final String value;
  final List<String> options;
  final ValueChanged<String?> onChanged;
  const _DropdownSetting(
      {required this.value, required this.options, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: value,
      underline: const SizedBox(),
      items: options
          .map((o) => DropdownMenuItem(
              value: o, child: Text(o, style: GoogleFonts.manrope(fontSize: 13))))
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
