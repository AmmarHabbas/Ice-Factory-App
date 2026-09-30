import 'package:flutter_test/flutter_test.dart';
import 'package:ice_cube_app/core/providers/currency_provider.dart';

void main() {
  test('SYP formatting isolates currency and digits from bidi context', () {
    expect(CurrencyFormatter.formatSYP(300), '\u2066SYP 300\u2069');
    expect(CurrencyFormatter.formatSYP(-300), '\u2066SYP -300\u2069');
  });
}
