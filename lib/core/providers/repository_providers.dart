import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'database_provider.dart';
import '../repositories/app_repository.dart';
import '../database/app_database.dart';

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return CustomerRepository(db);
});

final billRepositoryProvider = Provider<BillRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return BillRepository(db);
});

final tripRepositoryProvider = Provider<TripRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return TripRepository(db);
});

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return ExpenseRepository(db);
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return NotificationRepository(db);
});

final iceInventoryRepositoryProvider = Provider<IceInventoryRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return IceInventoryRepository(db);
});

// --- REACTIVE STREAMS ---
final allBillsStreamProvider = StreamProvider<List<Bill>>((ref) {
  return ref.watch(billRepositoryProvider).watchAllBills();
});

final iceBillsStreamProvider = StreamProvider<List<Bill>>((ref) {
  return ref.watch(billRepositoryProvider).watchIceBills();
});

final customBillsStreamProvider = StreamProvider<List<Bill>>((ref) {
  return ref.watch(billRepositoryProvider).watchCustomBills();
});

final allCustomersStreamProvider = StreamProvider<List<Customer>>((ref) {
  return ref.watch(customerRepositoryProvider).watchAllCustomers();
});

final topCustomersStreamProvider =
    StreamProvider<List<CustomerWithOrderCount>>((ref) {
  return ref.watch(customerRepositoryProvider).watchTopCustomersByOrderCount();
});

final allTripsStreamProvider = StreamProvider<List<Trip>>((ref) {
  return ref.watch(tripRepositoryProvider).watchAllTrips();
});

final allExpensesStreamProvider = StreamProvider<List<Expense>>((ref) {
  return ref.watch(expenseRepositoryProvider).watchAllExpenses();
});

final notificationsStreamProvider = StreamProvider<List<NotificationModel>>((ref) {
  return ref.watch(notificationRepositoryProvider).watchAllNotifications();
});

final todayIceSoldStreamProvider = StreamProvider<double>((ref) {
  return ref.watch(iceInventoryRepositoryProvider).watchTodayIceSold();
});

final iceInventoryStreamProvider =
    StreamProvider.family<IceInventorySnapshot, DateTime>((ref, date) {
  return ref.watch(iceInventoryRepositoryProvider).watchInventoryForDate(date);
});

final allBillItemsStreamProvider = StreamProvider<List<BillItem>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.billItems).watch();
});
