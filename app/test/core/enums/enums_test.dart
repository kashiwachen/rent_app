import 'package:flutter_test/flutter_test.dart';
import 'package:rent_tracker/core/enums/enums.dart';

void main() {
  group('PropertyType Enum Tests', () {
    test('should have correct enum values', () {
      expect(PropertyType.values.length, equals(2));
      expect(PropertyType.residential.value, equals('residential'));
      expect(PropertyType.commercial.value, equals('commercial'));
    });

    test('should convert from string using fromString', () {
      expect(
        PropertyType.fromString('residential'),
        equals(PropertyType.residential),
      );
      expect(
        PropertyType.fromString('commercial'),
        equals(PropertyType.commercial),
      );
    });

    test('should throw ArgumentError for invalid string', () {
      expect(
        () => PropertyType.fromString('invalid'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should handle case-sensitive strings', () {
      expect(
        () => PropertyType.fromString('Residential'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('PaymentCycle Enum Tests', () {
    test('should have correct enum values with months', () {
      expect(PaymentCycle.values.length, equals(4));

      expect(PaymentCycle.monthly.value, equals('monthly'));
      expect(PaymentCycle.monthly.months, equals(1));

      expect(PaymentCycle.bimonthly.value, equals('bimonthly'));
      expect(PaymentCycle.bimonthly.months, equals(2));

      expect(PaymentCycle.quarterly.value, equals('quarterly'));
      expect(PaymentCycle.quarterly.months, equals(3));

      expect(PaymentCycle.yearly.value, equals('yearly'));
      expect(PaymentCycle.yearly.months, equals(12));
    });

    test('should convert from string using fromString', () {
      expect(PaymentCycle.fromString('monthly'), equals(PaymentCycle.monthly));
      expect(
        PaymentCycle.fromString('bimonthly'),
        equals(PaymentCycle.bimonthly),
      );
      expect(
        PaymentCycle.fromString('quarterly'),
        equals(PaymentCycle.quarterly),
      );
      expect(PaymentCycle.fromString('yearly'), equals(PaymentCycle.yearly));
    });

    test('should throw ArgumentError for invalid string', () {
      expect(
        () => PaymentCycle.fromString('daily'),
        throwsA(isA<ArgumentError>()),
      );
      expect(() => PaymentCycle.fromString(''), throwsA(isA<ArgumentError>()));
    });

    test('months field should be correct for payment calculations', () {
      // This tests the critical business logic - payment cycle months
      expect(PaymentCycle.monthly.months, equals(1));
      expect(PaymentCycle.bimonthly.months, equals(2));
      expect(PaymentCycle.quarterly.months, equals(3));
      expect(PaymentCycle.yearly.months, equals(12));
    });
  });

  group('PaymentType Enum Tests', () {
    test('should have correct enum values', () {
      expect(PaymentType.values.length, equals(4));
      expect(PaymentType.rent.value, equals('rent'));
      expect(PaymentType.lateFee.value, equals('lateFee'));
      expect(PaymentType.deposit.value, equals('deposit'));
      expect(PaymentType.depositReturn.value, equals('depositReturn'));
    });

    test('should convert from string using fromString', () {
      expect(PaymentType.fromString('rent'), equals(PaymentType.rent));
      expect(PaymentType.fromString('lateFee'), equals(PaymentType.lateFee));
      expect(PaymentType.fromString('deposit'), equals(PaymentType.deposit));
      expect(
        PaymentType.fromString('depositReturn'),
        equals(PaymentType.depositReturn),
      );
    });

    test('should throw ArgumentError for invalid string', () {
      expect(
        () => PaymentType.fromString('unknown'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should use camelCase for values', () {
      // Verify camelCase convention for lateFee and depositReturn
      expect(PaymentType.lateFee.value, equals('lateFee'));
      expect(PaymentType.depositReturn.value, equals('depositReturn'));
    });
  });

  group('PaymentMethod Enum Tests', () {
    test('should have correct enum values', () {
      expect(PaymentMethod.values.length, equals(3));
      expect(PaymentMethod.bankTransfer.value, equals('bankTransfer'));
      expect(PaymentMethod.wechatPay.value, equals('wechatPay'));
      expect(PaymentMethod.cash.value, equals('cash'));
    });

    test('should convert from string using fromString', () {
      expect(
        PaymentMethod.fromString('bankTransfer'),
        equals(PaymentMethod.bankTransfer),
      );
      expect(
        PaymentMethod.fromString('wechatPay'),
        equals(PaymentMethod.wechatPay),
      );
      expect(PaymentMethod.fromString('cash'), equals(PaymentMethod.cash));
    });

    test('should throw ArgumentError for invalid string', () {
      expect(
        () => PaymentMethod.fromString('creditCard'),
        throwsA(isA<ArgumentError>()),
      );
      expect(() => PaymentMethod.fromString(''), throwsA(isA<ArgumentError>()));
    });

    test('should support Chinese payment methods', () {
      // Verify WeChat Pay is included (common in Chinese markets)
      expect(PaymentMethod.values, contains(PaymentMethod.wechatPay));
    });
  });

  group('ExpenseCategory Enum Tests', () {
    test('should have correct enum values', () {
      expect(ExpenseCategory.values.length, equals(3));
      expect(ExpenseCategory.maintenance.value, equals('maintenance'));
      expect(ExpenseCategory.repair.value, equals('repair'));
      expect(ExpenseCategory.other.value, equals('other'));
    });

    test('should convert from string using fromString', () {
      expect(
        ExpenseCategory.fromString('maintenance'),
        equals(ExpenseCategory.maintenance),
      );
      expect(
        ExpenseCategory.fromString('repair'),
        equals(ExpenseCategory.repair),
      );
      expect(
        ExpenseCategory.fromString('other'),
        equals(ExpenseCategory.other),
      );
    });

    test('should throw ArgumentError for invalid string', () {
      expect(
        () => ExpenseCategory.fromString('insurance'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should have catch-all "other" category', () {
      // Verify the "other" category exists for flexibility
      expect(ExpenseCategory.values, contains(ExpenseCategory.other));
    });
  });

  group('Enum Integration Tests', () {
    test('all enums should have fromString methods', () {
      // Verify all enums support string conversion
      expect(() => PropertyType.fromString('residential'), returnsNormally);
      expect(() => PaymentCycle.fromString('monthly'), returnsNormally);
      expect(() => PaymentType.fromString('rent'), returnsNormally);
      expect(() => PaymentMethod.fromString('cash'), returnsNormally);
      expect(() => ExpenseCategory.fromString('repair'), returnsNormally);
    });

    test('enum values should match database column constraints', () {
      // These values must match what's stored in the database
      // If these fail, update both database schema and enums together
      expect(PropertyType.residential.value, equals('residential'));
      expect(PropertyType.commercial.value, equals('commercial'));

      expect(PaymentCycle.monthly.value, equals('monthly'));
      expect(PaymentCycle.bimonthly.value, equals('bimonthly'));
      expect(PaymentCycle.quarterly.value, equals('quarterly'));
      expect(PaymentCycle.yearly.value, equals('yearly'));

      expect(PaymentType.rent.value, equals('rent'));
      expect(PaymentType.lateFee.value, equals('lateFee'));
      expect(PaymentType.deposit.value, equals('deposit'));
      expect(PaymentType.depositReturn.value, equals('depositReturn'));

      expect(PaymentMethod.bankTransfer.value, equals('bankTransfer'));
      expect(PaymentMethod.wechatPay.value, equals('wechatPay'));
      expect(PaymentMethod.cash.value, equals('cash'));

      expect(ExpenseCategory.maintenance.value, equals('maintenance'));
      expect(ExpenseCategory.repair.value, equals('repair'));
      expect(ExpenseCategory.other.value, equals('other'));
    });

    test('should handle null safety correctly', () {
      // Verify enums work with null safety
      const PropertyType? nullableType = null;
      expect(nullableType, isNull);

      const PropertyType nonNullType = PropertyType.residential;
      expect(nonNullType, isNotNull);
    });
  });
}
