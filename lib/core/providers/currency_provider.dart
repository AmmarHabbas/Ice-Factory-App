import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../database/app_database.dart';
import 'database_provider.dart';

class ExchangeRateNotifier extends StateNotifier<double> {
  final Ref ref;

  ExchangeRateNotifier(this.ref) : super(15000.0) {
    _loadRate();
  }

  Future<void> _loadRate() async {
    final db = ref.read(databaseProvider);
    final setting = await (db.select(db.appSettings)
          ..where((t) => t.key.equals('syp_rate')))
        .getSingleOrNull();
    if (setting != null) {
      final rate = double.tryParse(setting.value);
      if (rate != null && rate > 0) {
        state = rate;
      }
    }
  }

  Future<void> updateRate(double newRate) async {
    if (newRate <= 0) return;
    state = newRate;
    final db = ref.read(databaseProvider);
    await db.into(db.appSettings).insertOnConflictUpdate(
          AppSettingsCompanion.insert(
            key: 'syp_rate',
            value: newRate.toString(),
          ),
        );
  }
}

final exchangeRateProvider =
    StateNotifierProvider<ExchangeRateNotifier, double>((ref) {
  return ExchangeRateNotifier(ref);
});

class CurrencyFormatter {
  static String formatUSD(double amount) {
    final fmt = NumberFormat.currency(symbol: '\$ ', decimalDigits: 2);
    return fmt.format(amount);
  }

  static String formatSYP(double usdAmount, double rate) {
    final syp = usdAmount * rate;
    final fmt = NumberFormat.currency(symbol: 'ل.س ', decimalDigits: 0);
    return fmt.format(syp);
  }

  static String formatDual(double usdAmount, double rate) {
    final usdStr = formatUSD(usdAmount);
    final sypStr = formatSYP(usdAmount, rate);
    return '$usdStr\n($sypStr)';
  }

  static String formatDualSingleLine(double usdAmount, double rate) {
    final usdStr = formatUSD(usdAmount);
    final sypStr = formatSYP(usdAmount, rate);
    return '$usdStr ($sypStr)';
  }
}
