import 'package:flutter_test/flutter_test.dart';
import 'package:zollo/core/utils/formatters.dart';
import 'package:zollo/core/widgets/phone_field.dart';

void main() {
  group('formatTaka', () {
    test('whole values have no decimals and use thousands separators', () {
      expect(formatTaka(2450), '৳2,450');
      expect(formatTaka(60), '৳60');
      expect(formatTaka(1234567), '৳1,234,567');
      expect(formatTaka(2450.0), '৳2,450');
    });

    test('fractional values keep two decimals', () {
      expect(formatTaka(99.5), '৳99.50');
    });

    test('negative values keep the sign before the symbol', () {
      expect(formatTaka(-100), '-৳100');
    });
  });

  test('formatSold compacts thousands', () {
    expect(formatSold(3400), '3.4k sold');
    expect(formatSold(1000), '1k sold');
    expect(formatSold(120), '120 sold');
  });

  test('formatDate uses day and short month', () {
    expect(formatDate(DateTime(2026, 10, 13)), '13 Oct');
  });

  group('PhoneField validation', () {
    test('accepts 10-digit and 11-digit (leading 0) BD numbers', () {
      expect(PhoneField.isValid('1712345678'), isTrue);
      expect(PhoneField.isValid('01712345678'), isTrue);
      expect(PhoneField.isValid('+880 1712-345678'), isTrue);
    });

    test('rejects invalid operators and lengths', () {
      expect(PhoneField.isValid('1212345678'), isFalse);
      expect(PhoneField.isValid('17123'), isFalse);
    });

    test('optional field accepts empty input', () {
      expect(PhoneField.validate(''), isNull);
      expect(PhoneField.validate('', required: true), isNotNull);
    });
  });
}
