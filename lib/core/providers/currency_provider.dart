import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String formatSYP(double amount) {
    final fmt = NumberFormat.currency(symbol: 'SYP ', decimalDigits: 0);
    final formattedAmount = fmt.format(amount.abs());
    final number = formattedAmount.substring('SYP '.length);
    final sign = amount < 0 ? '-' : '';
    return '\u2066SYP $sign$number\u2069';
  }
}
