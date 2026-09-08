import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

@DataClassName('Customer')
class Customers extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get shopName => text()();
  TextColumn get ownerName => text()();
  TextColumn get phone => text()();
  TextColumn get address => text()();
  RealColumn get outstandingBalance =>
      real().withDefault(const Constant(0.0))();
  DateTimeColumn get lastVisit => dateTime().nullable()();
  TextColumn get category => text()(); // active, withDebt, new

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('Bill')
class Bills extends Table {
  TextColumn get id => text()(); // e.g., #INV-2023-0891
  TextColumn get customerId => text()();
  TextColumn get customerName => text()();
  DateTimeColumn get issueDate => dateTime()();
  DateTimeColumn get dueDate => dateTime()();
  TextColumn get status => text()(); // paid, partial, unpaid
  RealColumn get subtotal => real()();
  RealColumn get tax => real()();
  RealColumn get total => real()();
  RealColumn get paidAmount => real().withDefault(const Constant(0.0))();
  RealColumn get remainingAmount => real().withDefault(const Constant(0.0))();
  TextColumn get notes => text().nullable()();
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('BillItem')
class BillItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get billId => text()();
  TextColumn get productName => text()();
  TextColumn get unitSize => text()();
  IntColumn get quantity => integer()();
  RealColumn get unitPrice => real()();
  RealColumn get totalPrice => real()();
}

@DataClassName('Trip')
class Trips extends Table {
  TextColumn get id => text()();
  TextColumn get truckNumber => text()();
  TextColumn get driverName => text()();
  DateTimeColumn get date => dateTime()();
  TextColumn get status => text()(); // Completed, In Progress, Pending
  IntColumn get totalStops => integer()();
  IntColumn get completedStops => integer()();
  IntColumn get pendingStops => integer()();
  RealColumn get iceLoadKg => real().withDefault(const Constant(0.0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('TripStop')
class TripStops extends Table {
  TextColumn get id => text()();
  TextColumn get tripId => text()();
  IntColumn get stopNumber => integer()();
  TextColumn get customerId => text()();
  TextColumn get customerName => text()();
  TextColumn get address => text()();
  TextColumn get eta => text()();
  TextColumn get status => text()(); // Completed, In Progress, Pending
  TextColumn get estimatedQuantity => text()(); // "40 Bags"
  TextColumn get requiredTemperature => text()(); // "-18°C"

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('Expense')
class Expenses extends Table {
  TextColumn get id => text()();
  TextColumn get category =>
      text()(); // Fuel, Maintenance, Meals, Miscellaneous
  RealColumn get amount => real()();
  DateTimeColumn get date => dateTime()();
  TextColumn get description => text().nullable()();
  TextColumn get receiptPath => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('NotificationModel')
class Notifications extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get body => text()();
  DateTimeColumn get date => dateTime()();
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('AppSetting')
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DataClassName('IceInventoryEntry')
class IceInventoryEntries extends Table {
  TextColumn get id => text()();
  DateTimeColumn get date => dateTime()();
  RealColumn get amountKg => real()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    Customers,
    Bills,
    BillItems,
    Trips,
    TripStops,
    Expenses,
    Notifications,
    AppSettings,
    IceInventoryEntries,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(bills, bills.isCustom);
        await m.createTable(appSettings);
      }
      if (from < 3) {
        await m.addColumn(trips, trips.iceLoadKg);
        await m.createTable(iceInventoryEntries);
      }
    },
  );

  // Initializes default application settings without creating inventory data.
  Future<void> seedMockData() async {
    final sypRate = await (select(
      appSettings,
    )..where((t) => t.key.equals('syp_rate'))).getSingleOrNull();
    if (sypRate == null) {
      await into(
        appSettings,
      ).insert(const AppSetting(key: 'syp_rate', value: '15000.0'));
    }

    // Remove the legacy automatic batch from databases created by older builds.
    await (delete(
      iceInventoryEntries,
    )..where((entry) => entry.id.equals('INV-INIT-1'))).go();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'ice_cube_flow.db'));
    return NativeDatabase.createInBackground(file);
  });
}
