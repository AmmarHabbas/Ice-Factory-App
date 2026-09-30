import 'package:drift/drift.dart';
import '../database/app_database.dart';

// Helper to calculate ice weight in kg from product name and quantity
double calculateBillItemKg(String productName, int quantity) {
  final lower = productName.toLowerCase();
  double kgPerUnit = 1.0;
  if (lower.contains('1 kg') || lower.contains('1kg')) {
    kgPerUnit = 1.0;
  } else if (lower.contains('5 kgs') ||
      lower.contains('5kgs') ||
      lower.contains('5 kg') ||
      lower.contains('5kg')) {
    kgPerUnit = 5.0;
  } else if (lower.contains('10kg') || lower.contains('10 kg')) {
    kgPerUnit = 10.0;
  } else if (lower.contains('25kg') || lower.contains('25 kg')) {
    kgPerUnit = 25.0;
  } else {
    final match = RegExp(
      r'(\d+(?:\.\d+)?)\s*kg',
      caseSensitive: false,
    ).firstMatch(productName);
    if (match != null) {
      kgPerUnit = double.tryParse(match.group(1)!) ?? 1.0;
    } else {
      kgPerUnit = 1.0;
    }
  }
  return kgPerUnit * quantity;
}

Iterable<Bill> customerBillsOnly(Iterable<Bill> bills) =>
    bills.where((bill) => !bill.isCustom);

Iterable<Bill> customBillsOnly(Iterable<Bill> bills) =>
    bills.where((bill) => bill.isCustom);

double customerRevenue(Iterable<Bill> bills) =>
    customerBillsOnly(bills).fold(0.0, (sum, bill) => sum + bill.total);

double customExpenses(Iterable<Bill> bills) =>
    customBillsOnly(bills).fold(0.0, (sum, bill) => sum + bill.total);

double netRevenue(Iterable<Bill> bills) =>
    customerRevenue(bills) - customExpenses(bills);

// --- CUSTOMERS REPOSITORY ---
class CustomerRepository {
  final AppDatabase db;
  CustomerRepository(this.db);

  Future<List<Customer>> getAllCustomers() => db.select(db.customers).get();

  Stream<List<Customer>> watchAllCustomers() => db.select(db.customers).watch();

  Future<Customer?> getCustomerById(String id) => (db.select(
    db.customers,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> insertCustomer(Customer customer) =>
      db.into(db.customers).insert(customer, mode: InsertMode.insertOrReplace);

  Future<bool> updateCustomer(Customer customer) =>
      db.update(db.customers).replace(customer);

  /// Streams top customers ranked strictly by total order (bill) count in real time
  Stream<List<CustomerWithOrderCount>> watchTopCustomersByOrderCount() {
    return db.select(db.bills).watch().asyncMap((_) async {
      final customersList = await db.select(db.customers).get();
      final results = <CustomerWithOrderCount>[];
      for (var c in customersList) {
        final bills =
            await (db.select(db.bills)..where(
                  (b) =>
                      (b.customerId.equals(c.id) |
                          b.customerName.lower().equals(c.name.toLowerCase())) &
                      b.isCustom.equals(false),
                ))
                .get();
        results.add(
          CustomerWithOrderCount(customer: c, orderCount: bills.length),
        );
      }
      results.sort((a, b) => b.orderCount.compareTo(a.orderCount));
      return results;
    });
  }
}

class CustomerWithOrderCount {
  final Customer customer;
  final int orderCount;
  CustomerWithOrderCount({required this.customer, required this.orderCount});
}

// --- BILLS (INVOICES) REPOSITORY ---
class BillRepository {
  final AppDatabase db;
  BillRepository(this.db);

  Future<List<Bill>> getAllBills() => db.select(db.bills).get();

  Stream<List<Bill>> watchAllBills() => db.select(db.bills).watch();

  Stream<List<Bill>> watchIceBills() =>
      (db.select(db.bills)
            ..where((t) => t.isCustom.equals(false))
            ..orderBy([(t) => OrderingTerm.desc(t.issueDate)]))
          .watch();

  Stream<List<Bill>> watchCustomBills() =>
      (db.select(db.bills)
            ..where((t) => t.isCustom.equals(true))
            ..orderBy([(t) => OrderingTerm.desc(t.issueDate)]))
          .watch();

  Future<Bill?> getBillById(String id) =>
      (db.select(db.bills)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<BillItem>> getItemsForBill(String billId) =>
      (db.select(db.billItems)..where((t) => t.billId.equals(billId))).get();

  Future<void> deleteBill(Bill bill) async {
    await db.transaction(() async {
      if (!bill.isCustom &&
          (bill.status == 'unpaid' || bill.status == 'partial')) {
        final customer =
            await (db.select(db.customers)..where(
                  (t) =>
                      t.id.equals(bill.customerId) |
                      t.name.lower().equals(bill.customerName.toLowerCase()),
                ))
                .getSingleOrNull();
        if (customer != null) {
          final balance = customer.outstandingBalance - bill.remainingAmount;
          await db
              .update(db.customers)
              .replace(
                customer.copyWith(
                  outstandingBalance: balance < 0 ? 0.0 : balance,
                ),
              );
        }
      }

      await (db.delete(
        db.billItems,
      )..where((item) => item.billId.equals(bill.id))).go();
      await (db.delete(
        db.bills,
      )..where((item) => item.id.equals(bill.id))).go();
    });
  }

  Future<void> createBill(Bill bill, List<BillItemsCompanion> items) async {
    await db.transaction(() async {
      await db.into(db.bills).insert(bill, mode: InsertMode.insertOrReplace);
      for (var item in items) {
        await db.into(db.billItems).insert(item);
      }

      // Update customer balance if unpaid or partial
      if (bill.status == 'unpaid' || bill.status == 'partial') {
        final customer =
            await (db.select(db.customers)..where(
                  (t) =>
                      t.id.equals(bill.customerId) |
                      t.name.lower().equals(bill.customerName.toLowerCase()),
                ))
                .getSingleOrNull();
        if (customer != null) {
          final newBalance = customer.outstandingBalance + bill.remainingAmount;
          await db
              .update(db.customers)
              .replace(
                customer.copyWith(
                  outstandingBalance: newBalance,
                  lastVisit: Value(DateTime.now()),
                ),
              );
        }
      }
    });
  }

  Future<void> updatePaymentStatus(
    String billId,
    String status,
    double paidAmount,
  ) async {
    final bill = await getBillById(billId);
    if (bill == null) return;

    await db.transaction(() async {
      final newPaid = bill.paidAmount + paidAmount;
      final newRemaining = bill.total - newPaid;
      final updatedBill = bill.copyWith(
        status: status,
        paidAmount: newPaid,
        remainingAmount: newRemaining,
      );
      await db.update(db.bills).replace(updatedBill);

      // Adjust customer balance
      final customer =
          await (db.select(db.customers)..where(
                (t) =>
                    t.id.equals(bill.customerId) |
                    t.name.lower().equals(bill.customerName.toLowerCase()),
              ))
              .getSingleOrNull();
      if (customer != null) {
        final newBalance = customer.outstandingBalance - paidAmount;
        await db
            .update(db.customers)
            .replace(
              customer.copyWith(
                outstandingBalance: newBalance >= 0 ? newBalance : 0.0,
              ),
            );
      }
    });
  }
}

// --- TRIPS REPOSITORY ---
class TripRepository {
  final AppDatabase db;
  TripRepository(this.db);

  Future<List<Trip>> getAllTrips() => db.select(db.trips).get();

  Stream<List<Trip>> watchAllTrips() => db.select(db.trips).watch();

  Stream<List<Trip>> watchTripsForDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
    return (db.select(db.trips)
          ..where((t) => t.date.isBetweenValues(startOfDay, endOfDay))
          ..orderBy([(t) => OrderingTerm.asc(t.date)]))
        .watch();
  }

  Future<Trip?> getTripById(String id) =>
      (db.select(db.trips)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> createTrip(Trip trip, {TripStop? stop}) async {
    await db.transaction(() async {
      await db.into(db.trips).insert(trip, mode: InsertMode.insertOrReplace);
      if (stop != null) {
        await db
            .into(db.tripStops)
            .insert(stop, mode: InsertMode.insertOrReplace);
      }
    });
  }

  Future<void> updateTrip(Trip trip, {TripStop? stop}) async {
    await db.transaction(() async {
      await db.update(db.trips).replace(trip);
      if (stop != null) {
        await db
            .into(db.tripStops)
            .insert(stop, mode: InsertMode.insertOrReplace);
      }
    });
  }

  Future<List<TripStop>> getStopsForTrip(String tripId) =>
      (db.select(db.tripStops)..where((t) => t.tripId.equals(tripId))).get();

  Stream<List<TripStop>> watchStopsForTrip(String tripId) =>
      (db.select(db.tripStops)..where((t) => t.tripId.equals(tripId))).watch();

  Future<void> updateStopStatus(String stopId, String status) async {
    final stop = await (db.select(
      db.tripStops,
    )..where((t) => t.id.equals(stopId))).getSingleOrNull();
    if (stop == null) return;

    await db.transaction(() async {
      final updatedStop = stop.copyWith(status: status);
      await db.update(db.tripStops).replace(updatedStop);

      // Recalculate trip stop counters
      final tripId = stop.tripId;
      final stops = await getStopsForTrip(tripId);
      int completed = 0;
      int pending = 0;
      for (var s in stops) {
        if (s.id == stopId ? status == 'Completed' : s.status == 'Completed') {
          completed++;
        } else {
          pending++;
        }
      }

      final trip = await getTripById(tripId);
      if (trip != null) {
        String tripStatus = trip.status;
        if (completed == trip.totalStops) {
          tripStatus = 'Completed';
        } else if (completed > 0) {
          tripStatus = 'In Progress';
        }
        await db
            .update(db.trips)
            .replace(
              trip.copyWith(
                completedStops: completed,
                pendingStops: pending,
                status: tripStatus,
              ),
            );
      }
    });
  }
}

// --- ICE INVENTORY REPOSITORY ---
class IceInventorySnapshot {
  final DateTime date;
  final double openingBalance;
  final double totalAdded;
  final double totalSold;
  final double available;
  final List<IceInventoryAdjustment> adjustments;

  IceInventorySnapshot({
    required this.date,
    required this.openingBalance,
    required this.totalAdded,
    required this.totalSold,
    required this.available,
    required this.adjustments,
  });
}

class IceInventoryAdjustment {
  final String id;
  final String title;
  final DateTime timestamp;
  final double amountKg;
  final bool isAddition;

  IceInventoryAdjustment({
    required this.id,
    required this.title,
    required this.timestamp,
    required this.amountKg,
    required this.isAddition,
  });
}

class IceInventoryRepository {
  final AppDatabase db;
  IceInventoryRepository(this.db);

  Stream<IceInventorySnapshot> watchInventoryForDate(DateTime date) {
    final startOfDay = _normalizeDate(date);
    final startOfNextDay = startOfDay.add(const Duration(days: 1));

    return Stream.multi((multi) {
      Future<void> emitSnapshot() async {
        final previousEntries = await (db.select(
          db.iceInventoryEntries,
        )..where((entry) => entry.date.isSmallerThanValue(startOfDay))).get();
        final previousBills =
            await (db.select(db.bills)..where(
                  (bill) => bill.issueDate.isSmallerThanValue(startOfDay),
                ))
                .get();
        final entries =
            await (db.select(db.iceInventoryEntries)
                  ..where(
                    (entry) => entry.date.isBetweenValues(
                      startOfDay,
                      startOfNextDay.subtract(const Duration(microseconds: 1)),
                    ),
                  )
                  ..orderBy([(entry) => OrderingTerm.asc(entry.createdAt)]))
                .get();
        final bills =
            await (db.select(db.bills)
                  ..where(
                    (bill) => bill.issueDate.isBetweenValues(
                      startOfDay,
                      startOfNextDay.subtract(const Duration(microseconds: 1)),
                    ),
                  )
                  ..orderBy([(bill) => OrderingTerm.asc(bill.issueDate)]))
                .get();

        final openingBalance =
            previousEntries.fold<double>(
              0,
              (sum, entry) => sum + entry.amountKg,
            ) -
            await _calculateTotalSold(previousBills);
        final snapshot = await _buildInventorySnapshot(
          date,
          entries,
          bills,
          openingBalance,
        );
        multi.add(snapshot);
      }

      final subscriptions = [
        db.select(db.iceInventoryEntries).watch().listen((_) => emitSnapshot()),
        db.select(db.bills).watch().listen((_) => emitSnapshot()),
        db.select(db.billItems).watch().listen((_) => emitSnapshot()),
      ];

      multi.onCancel = () async {
        for (final subscription in subscriptions) {
          await subscription.cancel();
        }
      };
    });
  }

  Future<IceInventorySnapshot> _buildInventorySnapshot(
    DateTime date,
    List<IceInventoryEntry> entries,
    List<Bill> bills,
    double openingBalance,
  ) async {
    double totalSold = 0.0;
    final adjustments = <IceInventoryAdjustment>[];

    for (var entry in entries) {
      adjustments.add(
        IceInventoryAdjustment(
          id: entry.id,
          title: entry.notes ?? 'New Production Added',
          timestamp: entry.createdAt,
          amountKg: entry.amountKg,
          isAddition: true,
        ),
      );
    }

    for (var bill in bills) {
      if (bill.isCustom) continue;
      final items = await (db.select(
        db.billItems,
      )..where((i) => i.billId.equals(bill.id))).get();
      double billKg = 0.0;
      for (var item in items) {
        billKg += calculateBillItemKg(item.productName, item.quantity);
      }
      if (billKg > 0) {
        totalSold += billKg;
        adjustments.add(
          IceInventoryAdjustment(
            id: bill.id,
            title: 'Invoice ${bill.id} (${bill.customerName})',
            timestamp: bill.issueDate,
            amountKg: billKg,
            isAddition: false,
          ),
        );
      }
    }

    final totalAdded = entries.fold<double>(
      0.0,
      (sum, item) => sum + item.amountKg,
    );
    final available = openingBalance + totalAdded - totalSold;

    adjustments.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return IceInventorySnapshot(
      date: date,
      openingBalance: openingBalance,
      totalAdded: totalAdded,
      totalSold: totalSold,
      available: available,
      adjustments: adjustments,
    );
  }

  Future<double> _calculateTotalSold(List<Bill> bills) async {
    double totalSold = 0.0;
    for (final bill in bills) {
      if (bill.isCustom) continue;
      final items = await (db.select(
        db.billItems,
      )..where((item) => item.billId.equals(bill.id))).get();
      for (final item in items) {
        totalSold += calculateBillItemKg(item.productName, item.quantity);
      }
    }
    return totalSold;
  }

  Future<void> addIceInventory({
    required double amountKg,
    DateTime? date,
    String? notes,
  }) async {
    final now = DateTime.now();
    final targetDate = date ?? now;
    final normalizedDate = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
    );
    await db
        .into(db.iceInventoryEntries)
        .insert(
          IceInventoryEntry(
            id: 'INV-${DateTime.now().millisecondsSinceEpoch}',
            date: normalizedDate,
            amountKg: amountKg,
            notes: notes ?? 'Production Addition',
            createdAt: now,
          ),
        );
  }

  Future<void> updateIceInventory({
    required String id,
    required double amountKg,
    required String notes,
  }) async {
    final existing = await (db.select(
      db.iceInventoryEntries,
    )..where((entry) => entry.id.equals(id))).getSingleOrNull();
    if (existing == null) return;

    await db
        .update(db.iceInventoryEntries)
        .replace(existing.copyWith(amountKg: amountKg, notes: Value(notes)));
  }

  Future<void> deleteIceInventory(String id) async {
    await (db.delete(
      db.iceInventoryEntries,
    )..where((entry) => entry.id.equals(id))).go();
  }

  DateTime _normalizeDate(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  Stream<double> watchTodayIceSold() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

    return (db.select(db.bills)
          ..where((b) => b.issueDate.isBetweenValues(startOfDay, endOfDay)))
        .watch()
        .asyncMap((bills) async {
          double totalKg = 0.0;
          for (var bill in bills) {
            if (bill.isCustom) continue;
            final items = await (db.select(
              db.billItems,
            )..where((i) => i.billId.equals(bill.id))).get();
            for (var item in items) {
              totalKg += calculateBillItemKg(item.productName, item.quantity);
            }
          }
          return totalKg;
        });
  }
}

// --- EXPENSES REPOSITORY ---
class ExpenseRepository {
  final AppDatabase db;
  ExpenseRepository(this.db);

  Future<List<Expense>> getAllExpenses() => db.select(db.expenses).get();

  Stream<List<Expense>> watchAllExpenses() => db.select(db.expenses).watch();

  Future<int> addExpense(Expense expense) =>
      db.into(db.expenses).insert(expense);
}

// --- WORKERS REPOSITORY ---
class WorkerRepository {
  final AppDatabase db;
  WorkerRepository(this.db);

  Stream<List<Worker>> watchAllWorkers() => (db.select(
    db.workers,
  )..orderBy([(w) => OrderingTerm.asc(w.firstName)])).watch();

  Future<List<Worker>> getAllWorkers() => db.select(db.workers).get();

  Future<Worker?> getWorkerById(String id) =>
      (db.select(db.workers)..where((w) => w.id.equals(id))).getSingleOrNull();

  Future<void> addWorker(Worker worker) async {
    await db.into(db.workers).insert(worker, mode: InsertMode.insertOrReplace);
  }

  Future<void> updateWorker(Worker worker) async {
    await db.update(db.workers).replace(worker);
  }

  Future<void> deleteWorker(String id) async {
    await (db.delete(db.workers)..where((w) => w.id.equals(id))).go();
  }

  Stream<List<WorkerPayment>> watchPaymentsForWorker(String workerId) =>
      (db.select(db.workerPayments)
            ..where((p) => p.workerId.equals(workerId))
            ..orderBy([(p) => OrderingTerm.desc(p.date)]))
          .watch();

  Stream<List<WorkerPayment>> watchAllPayments() => (db.select(
    db.workerPayments,
  )..orderBy([(p) => OrderingTerm.desc(p.date)])).watch();

  /// Records a salary payment and reduces loanBalance if type is loan_repayment.
  Future<void> addPayment(WorkerPayment payment) async {
    await db.transaction(() async {
      await db.into(db.workerPayments).insert(payment);

      if (payment.type == 'loan_advance') {
        final worker = await getWorkerById(payment.workerId);
        if (worker != null) {
          await db
              .update(db.workers)
              .replace(
                worker.copyWith(
                  loanBalance: worker.loanBalance + payment.amount,
                ),
              );
        }
      } else if (payment.type == 'loan_repayment') {
        final worker = await getWorkerById(payment.workerId);
        if (worker != null) {
          final newBalance = worker.loanBalance - payment.amount;
          await db
              .update(db.workers)
              .replace(
                worker.copyWith(loanBalance: newBalance < 0 ? 0.0 : newBalance),
              );
        }
      }
    });
  }

  /// Total salary costs paid in a date range (type: salary).
  Future<double> totalSalaryCostForRange(
    DateTime rangeStart,
    DateTime rangeEnd,
  ) async {
    final payments =
        await (db.select(db.workerPayments)..where(
              (p) =>
                  p.type.equals('salary') &
                  p.date.isBiggerOrEqualValue(rangeStart) &
                  p.date.isSmallerOrEqualValue(rangeEnd),
            ))
            .get();
    return payments.fold<double>(0.0, (sum, p) => sum + p.amount);
  }

  /// Stream of total salary + loan_advance disbursed today.
  Stream<double> watchTodayWorkerCosts() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    return (db.select(db.workerPayments)..where(
          (p) =>
              p.date.isBetweenValues(startOfDay, endOfDay) &
              (p.type.equals('salary') | p.type.equals('loan_advance')),
        ))
        .watch()
        .map((list) => list.fold<double>(0.0, (sum, p) => sum + p.amount));
  }

  /// Stream of all salary/loan disbursements in a range.
  Stream<List<WorkerPayment>> watchPaymentsForRange(
    DateTime rangeStart,
    DateTime rangeEnd,
  ) =>
      (db.select(db.workerPayments)
            ..where(
              (p) =>
                  p.date.isBiggerOrEqualValue(rangeStart) &
                  p.date.isSmallerOrEqualValue(rangeEnd),
            )
            ..orderBy([(p) => OrderingTerm.desc(p.date)]))
          .watch();

  /// Total active loan debt across all workers.
  Stream<double> watchTotalLoanBalance() => db
      .select(db.workers)
      .watch()
      .map((list) => list.fold(0.0, (sum, w) => sum + w.loanBalance));
}

// --- NOTIFICATIONS REPOSITORY ---
class NotificationRepository {
  final AppDatabase db;
  NotificationRepository(this.db);

  Future<List<NotificationModel>> getAllNotifications() =>
      db.select(db.notifications).get();

  Stream<List<NotificationModel>> watchAllNotifications() =>
      db.select(db.notifications).watch();

  Future<int> getUnreadCount() async {
    final list = await (db.select(
      db.notifications,
    )..where((t) => t.isRead.equals(false))).get();
    return list.length;
  }

  Future<void> markAsRead(String id) async {
    final notif = await (db.select(
      db.notifications,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (notif != null) {
      await db.update(db.notifications).replace(notif.copyWith(isRead: true));
    }
  }

  Future<void> markAllAsRead() async {
    final list = await (db.select(
      db.notifications,
    )..where((t) => t.isRead.equals(false))).get();
    for (var notif in list) {
      await db.update(db.notifications).replace(notif.copyWith(isRead: true));
    }
  }
}
