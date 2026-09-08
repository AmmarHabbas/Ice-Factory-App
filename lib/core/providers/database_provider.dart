import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  // Call seeder in background to ensure we have data immediately
  db.seedMockData();
  return db;
});
