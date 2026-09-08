import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  final String currentLocation;

  const MainShell({
    super.key,
    required this.child,
    required this.currentLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: child,
      bottomNavigationBar: _BottomNavBar(currentLocation: currentLocation),
    );
  }
}

// ─── Bottom Navigation Bar ───────────────────────────────────────────────────
class _BottomNavBar extends StatelessWidget {
  final String currentLocation;
  const _BottomNavBar({required this.currentLocation});

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavItem(
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard,
        label: 'Dashboard',
        path: '/dashboard',
      ),
      _NavItem(
        icon: Icons.event_note_outlined,
        activeIcon: Icons.event_note,
        label: 'Schedule',
        path: '/schedule',
      ),
      _NavItem(
        icon: Icons.receipt_long_outlined,
        activeIcon: Icons.receipt_long,
        label: 'Invoices',
        path: '/bills',
      ),
      _NavItem(
        icon: Icons.group_outlined,
        activeIcon: Icons.group,
        label: 'Customers',
        path: '/customers',
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.92),
        border: const Border(
          top: BorderSide(color: AppColors.outlineVariant, width: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            children: items.map((item) {
              final isActive = currentLocation.startsWith(item.path);
              return Expanded(
                child: GestureDetector(
                  onTap: () => context.go(item.path),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.secondaryContainer.withValues(alpha: 0.4)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusSmall,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isActive ? item.activeIcon : item.icon,
                          color: isActive
                              ? AppColors.primary
                              : AppColors.onSurfaceVariant,
                          size: 22,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.label,
                          style: GoogleFonts.manrope(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: isActive
                                ? AppColors.primary
                                : AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String path;
  _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.path,
  });
}

// ─── App Header ───────────────────────────────────────────────────────────────
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showMenuButton;
  final List<Widget>? actions;

  const AppHeader({
    super.key,
    required this.title,
    this.showMenuButton = true,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.gutter,
            ),
            child: Row(
              children: [
                if (showMenuButton)
                  GestureDetector(
                    onTap: () => Scaffold.of(context).openDrawer(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.transparent,
                      ),
                      child: const Icon(
                        Icons.menu,
                        color: AppColors.onSurface,
                        size: 24,
                      ),
                    ),
                  ),
                if (showMenuButton) const SizedBox(width: AppDimensions.md),
                if (!showMenuButton)
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surfaceContainer,
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: AppColors.onSurface,
                        size: 22,
                      ),
                    ),
                  ),
                if (!showMenuButton) const SizedBox(width: AppDimensions.md),
                // Logo mark
                Container(
                  width: 32,
                  height: 32,
                  margin: const EdgeInsets.only(right: AppDimensions.sm),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.ac_unit,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const Spacer(),
                ...(actions ?? []),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(64);
}

// ─── Navigation Drawer ────────────────────────────────────────────────────────
class AppNavigationDrawer extends StatelessWidget {
  final String currentLocation;
  const AppNavigationDrawer({super.key, required this.currentLocation});

  @override
  Widget build(BuildContext context) {
    final navItems = [
      _DrawerItem(
        icon: Icons.dashboard_outlined,
        label: 'Dashboard',
        path: '/dashboard',
      ),
      _DrawerItem(
        icon: Icons.receipt_long_outlined,
        label: 'Bills',
        path: '/bills',
      ),
      _DrawerItem(
        icon: Icons.inventory_2_outlined,
        label: 'Ice Inventory',
        path: '/ice-inventory',
      ),
      _DrawerItem(
        icon: Icons.calendar_today_outlined,
        label: "Today's Schedule",
        path: '/schedule',
      ),
      _DrawerItem(
        icon: Icons.group_outlined,
        label: 'Customers',
        path: '/customers',
      ),
    ];
    final secondaryItems = [
      _DrawerItem(
        icon: Icons.description_outlined,
        label: 'Reports',
        path: '/reports',
      ),
      _DrawerItem(
        icon: Icons.bar_chart_outlined,
        label: 'Statistics',
        path: '/statistics',
      ),
      _DrawerItem(
        icon: Icons.settings_outlined,
        label: 'Settings',
        path: '/settings',
      ),
      _DrawerItem(
        icon: Icons.search_outlined,
        label: 'Search',
        path: '/search',
      ),
    ];

    return Drawer(
      backgroundColor: AppColors.surfaceContainerLowest,
      width: 280,
      child: SafeArea(
        child: Column(
          children: [
            // Brand Header
            Container(
              padding: const EdgeInsets.all(AppDimensions.lg),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.outlineVariant,
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.ac_unit,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fawares Al Sham',
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface,
                        ),
                      ),
                      Text(
                        'Ice Cube Distribution',
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Primary Nav Items
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: AppDimensions.sm),
                child: Column(
                  children: [
                    ...navItems.map((item) => _buildDrawerItem(context, item)),
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppDimensions.md,
                        vertical: AppDimensions.sm,
                      ),
                      child: Divider(
                        color: AppColors.outlineVariant,
                        height: 1,
                      ),
                    ),
                    ...secondaryItems.map(
                      (item) => _buildDrawerItem(context, item),
                    ),
                  ],
                ),
              ),
            ),
            // Logout
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.outlineVariant, width: 0.5),
                ),
              ),
              child: ListTile(
                leading: const Icon(Icons.logout, color: AppColors.error),
                title: Text(
                  'Logout',
                  style: GoogleFonts.manrope(color: AppColors.error),
                ),
                onTap: () => context.go('/onboarding'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, _DrawerItem item) {
    final isActive = currentLocation.startsWith(item.path);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.sm,
        vertical: 1,
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
        tileColor: isActive
            ? AppColors.secondaryContainer.withValues(alpha: 0.2)
            : Colors.transparent,
        leading: Icon(
          item.icon,
          color: isActive ? AppColors.primary : AppColors.onSurfaceVariant,
          size: 22,
        ),
        title: Text(
          item.label,
          style: GoogleFonts.manrope(
            color: isActive ? AppColors.primary : AppColors.onSurfaceVariant,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            fontSize: 14,
          ),
        ),
        onTap: () {
          Navigator.of(context).pop();
          context.go(item.path);
        },
      ),
    );
  }
}

class _DrawerItem {
  final IconData icon;
  final String label;
  final String path;
  _DrawerItem({required this.icon, required this.label, required this.path});
}
