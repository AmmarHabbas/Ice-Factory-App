import 'package:go_router/go_router.dart';
import 'package:ice_cube_app/features/login/login_screen.dart';
import 'package:ice_cube_app/features/schedule/add_new_trip.dart';
import 'package:ice_cube_app/features/workers/add_worker_screen.dart';
import 'package:ice_cube_app/features/workers/workers_screen.dart';
import '../../core/database/app_database.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/bills/bills_screen.dart';
import '../../features/bills/invoice_detail_screen.dart';
import '../../features/bills/new_invoice_screen.dart';
import '../../features/customers/customer_directory_screen.dart';
import '../../features/customers/customer_detail_screen.dart';
import '../../features/customers/add_customer_screen.dart';
import '../../features/inventory/ice_inventory_screen.dart';
import '../../features/schedule/schedule_screen.dart';
import '../../features/schedule/trip_detail_screen.dart';
import '../../features/reports/reports_screen.dart';
import '../../features/statistics/statistics_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/search/search_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(path: '/', redirect: (_, __) => '/login'),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/bills',
      builder: (context, state) => const BillsScreen(),
      routes: [
        GoRoute(
          path: 'detail',
          builder: (context, state) =>
              InvoiceDetailScreen(bill: state.extra as Bill?),
        ),
        GoRoute(
          path: 'create',
          builder: (context, state) => const NewInvoiceScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/ice-inventory',
      builder: (context, state) => const IceInventoryScreen(),
    ),
    GoRoute(
      path: '/customers',
      builder: (context, state) => const CustomerDirectoryScreen(),
      routes: [
        GoRoute(
          path: 'detail',
          builder: (context, state) =>
              CustomerDetailScreen(customer: state.extra as Customer?),
        ),
        GoRoute(
          path: 'add',
          builder: (context, state) => const AddCustomerScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/schedule',
      builder: (context, state) => const ScheduleScreen(),
    ),
    GoRoute(
      path: '/workers',
      builder: (context, state) => const WorkersScreen(),
    ),
    GoRoute(
      path: '/addworkers',
      builder: (context, state) => const AddWorkerScreen(),
    ),
    GoRoute(
      path: '/reports',
      builder: (context, state) => const ReportsScreen(),
    ),
    GoRoute(
      path: '/statistics',
      builder: (context, state) => const StatisticsScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(path: '/search', builder: (context, state) => const SearchScreen()),
    GoRoute(
      path: '/schedule/add-trip',
      builder: (context, state) => const AddNewTrip(),
    ),
    GoRoute(
      path: '/schedule/trip-detail',
      builder: (context, state) => TripDetailScreen(trip: state.extra as Trip),
    ),
  ],
);
