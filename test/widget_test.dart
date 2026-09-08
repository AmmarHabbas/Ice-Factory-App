import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ice_cube_app/core/theme/light_theme.dart';
import 'package:ice_cube_app/features/settings/settings_screen.dart';
import 'package:ice_cube_app/features/schedule/schedule_screen.dart';
import 'package:ice_cube_app/features/inventory/ice_inventory_screen.dart';
import 'package:ice_cube_app/features/dashboard/dashboard_screen.dart';
import 'package:ice_cube_app/features/statistics/statistics_screen.dart';
import 'package:ice_cube_app/features/bills/bills_screen.dart';
import 'package:ice_cube_app/features/customers/customer_directory_screen.dart';
import 'package:ice_cube_app/features/customers/customer_detail_screen.dart';
import 'package:ice_cube_app/main.dart';

void main() {
  testWidgets('IceCubeApp initializes cleanly', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: IceCubeApp()));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(IceCubeApp), findsOneWidget);
  });

  testWidgets('SettingsScreen pumps without error', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: getLightTheme(),
          home: const SettingsScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(SettingsScreen), findsOneWidget);
  });

  testWidgets('DashboardScreen pumps without error', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: getLightTheme(),
          home: const DashboardScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(DashboardScreen), findsOneWidget);
  });

  testWidgets('ScheduleScreen pumps without error', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: getLightTheme(),
          home: const ScheduleScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(ScheduleScreen), findsOneWidget);
  });

  testWidgets('IceInventoryScreen pumps without error', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: getLightTheme(),
          home: const IceInventoryScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(IceInventoryScreen), findsOneWidget);
  });

  testWidgets('StatisticsScreen pumps without error', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: getLightTheme(),
          home: const StatisticsScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(StatisticsScreen), findsOneWidget);
  });

  testWidgets('BillsScreen pumps without error', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: getLightTheme(),
          home: const BillsScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(BillsScreen), findsOneWidget);
  });

  testWidgets('CustomerDirectoryScreen pumps without error', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: getLightTheme(),
          home: const CustomerDirectoryScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(CustomerDirectoryScreen), findsOneWidget);
  });

  testWidgets('CustomerDetailScreen pumps without error', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: getLightTheme(),
          home: const CustomerDetailScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(CustomerDetailScreen), findsOneWidget);
  });
}
