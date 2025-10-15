/// Unit tests for ExpenseRepository
///
/// Tests all methods following TDD principles
library;

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import '../../lib/core/database/app_database.dart';
import '../../lib/core/enums/enums.dart';
import '../../lib/repositories/expense_repository.dart';
import '../helpers/database_helper.dart';

void main() {
  late AppDatabase db;
  late ExpenseRepository repository;

  setUp(() {
    db = createTestDatabase();
    repository = ExpenseRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('ExpenseRepository - CRUD Operations', () {
    test('addExpense - should create a new maintenance expense', () async {
      // Arrange
      final propertyIds = await seedTestProperties(db);

      // Act
      final expense = await repository.addExpense(
        propertyId: propertyIds[0],
        amount: 500.0,
        category: ExpenseCategory.maintenance,
        date: DateTime.now(),
        description: 'Monthly cleaning',
      );

      // Assert
      expect(expense.id, greaterThan(0));
      expect(expense.propertyId, propertyIds[0]);
      expect(expense.amount, 500.0);
      expect(expense.category, ExpenseCategory.maintenance.value);
      expect(expense.description, 'Monthly cleaning');
      expect(expense.createdAt, isNotNull);
    });

    test('addExpense - should create expense with notes', () async {
      // Arrange
      final propertyIds = await seedTestProperties(db);

      // Act
      final expense = await repository.addExpense(
        propertyId: propertyIds[0],
        amount: 1500.0,
        category: ExpenseCategory.repair,
        date: DateTime.now(),
        description: 'HVAC repair',
        notes: 'Emergency repair - AC unit failed',
      );

      // Assert
      expect(expense.id, greaterThan(0));
      expect(expense.category, ExpenseCategory.repair.value);
    });

    test('addExpense - should throw when property does not exist', () async {
      // Act & Assert
      expect(
        () => repository.addExpense(
          propertyId: 999,
          amount: 100.0,
          category: ExpenseCategory.other,
          date: DateTime.now(),
          description: 'Test',
        ),
        throwsException,
      );
    });

    test(
      'getAllExpenses - should return empty list when no expenses exist',
      () async {
        // Act
        final expenses = await repository.getAllExpenses();

        // Assert
        expect(expenses, isEmpty);
      },
    );

    test('getAllExpenses - should return all expenses', () async {
      // Arrange
      final propertyIds = await seedTestProperties(db);
      await repository.addExpense(
        propertyId: propertyIds[0],
        amount: 500.0,
        category: ExpenseCategory.maintenance,
        date: DateTime.now(),
        description: 'Expense 1',
      );
      await repository.addExpense(
        propertyId: propertyIds[1],
        amount: 1000.0,
        category: ExpenseCategory.repair,
        date: DateTime.now(),
        description: 'Expense 2',
      );

      // Act
      final expenses = await repository.getAllExpenses();

      // Assert
      expect(expenses, hasLength(2));
    });

    test(
      'getExpensesByProperty - should return empty list when no expenses',
      () async {
        // Arrange
        final propertyIds = await seedTestProperties(db);

        // Act
        final expenses = await repository.getExpensesByProperty(propertyIds[0]);

        // Assert
        expect(expenses, isEmpty);
      },
    );

    test(
      'getExpensesByProperty - should return only expenses for property',
      () async {
        // Arrange
        final propertyIds = await seedTestProperties(db);
        await repository.addExpense(
          propertyId: propertyIds[0],
          amount: 500.0,
          category: ExpenseCategory.maintenance,
          date: DateTime.now(),
          description: 'Property 1 Expense 1',
        );
        await repository.addExpense(
          propertyId: propertyIds[0],
          amount: 600.0,
          category: ExpenseCategory.repair,
          date: DateTime.now(),
          description: 'Property 1 Expense 2',
        );
        await repository.addExpense(
          propertyId: propertyIds[1],
          amount: 1000.0,
          category: ExpenseCategory.other,
          date: DateTime.now(),
          description: 'Property 2 Expense',
        );

        // Act
        final expenses = await repository.getExpensesByProperty(propertyIds[0]);

        // Assert
        expect(expenses, hasLength(2));
        expect(expenses.every((e) => e.propertyId == propertyIds[0]), isTrue);
      },
    );

    test(
      'getExpensesByProperty - should return expenses ordered by date descending',
      () async {
        // Arrange
        final propertyIds = await seedTestProperties(db);
        final now = DateTime.now();

        await repository.addExpense(
          propertyId: propertyIds[0],
          amount: 100.0,
          category: ExpenseCategory.maintenance,
          date: now.subtract(const Duration(days: 30)),
          description: 'Old expense',
        );
        await repository.addExpense(
          propertyId: propertyIds[0],
          amount: 200.0,
          category: ExpenseCategory.repair,
          date: now,
          description: 'Recent expense',
        );
        await repository.addExpense(
          propertyId: propertyIds[0],
          amount: 150.0,
          category: ExpenseCategory.other,
          date: now.subtract(const Duration(days: 15)),
          description: 'Middle expense',
        );

        // Act
        final expenses = await repository.getExpensesByProperty(propertyIds[0]);

        // Assert
        expect(expenses, hasLength(3));
        expect(expenses[0].description, 'Recent expense'); // Most recent first
        expect(expenses[1].description, 'Middle expense');
        expect(expenses[2].description, 'Old expense');
      },
    );
  });

  group('ExpenseRepository - Business Logic', () {
    test(
      'calculateYearlyExpenses - should return 0 when no expenses exist',
      () async {
        // Act
        final total = await repository.calculateYearlyExpenses(2025);

        // Assert
        expect(total, 0.0);
      },
    );

    test(
      'calculateYearlyExpenses - should sum expenses for given year',
      () async {
        // Arrange
        final propertyIds = await seedTestProperties(db);
        final year2025 = DateTime(2025, 6, 15);
        final year2024 = DateTime(2024, 6, 15);

        await repository.addExpense(
          propertyId: propertyIds[0],
          amount: 500.0,
          category: ExpenseCategory.maintenance,
          date: year2025,
          description: '2025 Expense 1',
        );
        await repository.addExpense(
          propertyId: propertyIds[0],
          amount: 1000.0,
          category: ExpenseCategory.repair,
          date: year2025,
          description: '2025 Expense 2',
        );
        await repository.addExpense(
          propertyId: propertyIds[1],
          amount: 800.0,
          category: ExpenseCategory.other,
          date: year2024,
          description: '2024 Expense (should be ignored)',
        );

        // Act
        final total = await repository.calculateYearlyExpenses(2025);

        // Assert
        expect(total, 1500.0);
      },
    );

    test(
      'calculateYearlyExpenses - should handle year boundaries correctly',
      () async {
        // Arrange
        final propertyIds = await seedTestProperties(db);

        // Last day of 2024
        await repository.addExpense(
          propertyId: propertyIds[0],
          amount: 500.0,
          category: ExpenseCategory.maintenance,
          date: DateTime(2024, 12, 31),
          description: '2024 Expense',
        );

        // First day of 2025
        await repository.addExpense(
          propertyId: propertyIds[0],
          amount: 1000.0,
          category: ExpenseCategory.repair,
          date: DateTime(2025, 1, 1),
          description: '2025 Expense',
        );

        // Act
        final total2024 = await repository.calculateYearlyExpenses(2024);
        final total2025 = await repository.calculateYearlyExpenses(2025);

        // Assert
        expect(total2024, 500.0);
        expect(total2025, 1000.0);
      },
    );

    test(
      'calculateProfitLoss - should return negative when expenses exceed income',
      () async {
        // Arrange
        final propertyIds = await seedTestProperties(db);
        final tenantIds = await seedTestTenants(db);
        final contractIds = await seedTestContracts(db, propertyIds, tenantIds);

        // Add 2025 expenses
        await repository.addExpense(
          propertyId: propertyIds[0],
          amount: 10000.0,
          category: ExpenseCategory.repair,
          date: DateTime(2025, 6, 15),
          description: 'Major repair',
        );

        // Add 2025 payment (income)
        await db
            .into(db.payments)
            .insert(
              PaymentsCompanion.insert(
                contractId: contractIds[0],
                amount: 1000.0,
                paidDate: DateTime(2025, 6, 1),
                dueDate: DateTime(2025, 6, 1),
                paymentType: PaymentType.rent.value,
                paymentMethod: PaymentMethod.bankTransfer.value,
              ),
            );

        // Act
        final profitLoss = await repository.calculateProfitLoss(2025);

        // Assert
        expect(profitLoss, -9000.0); // Loss of 9000
      },
    );

    test(
      'calculateProfitLoss - should return positive when income exceeds expenses',
      () async {
        // Arrange
        final propertyIds = await seedTestProperties(db);
        final tenantIds = await seedTestTenants(db);
        final contractIds = await seedTestContracts(db, propertyIds, tenantIds);

        // Add 2025 expenses
        await repository.addExpense(
          propertyId: propertyIds[0],
          amount: 500.0,
          category: ExpenseCategory.maintenance,
          date: DateTime(2025, 6, 15),
          description: 'Small maintenance',
        );

        // Add 2025 payments (income)
        await db
            .into(db.payments)
            .insert(
              PaymentsCompanion.insert(
                contractId: contractIds[0],
                amount: 5000.0,
                paidDate: DateTime(2025, 6, 1),
                dueDate: DateTime(2025, 6, 1),
                paymentType: PaymentType.rent.value,
                paymentMethod: PaymentMethod.bankTransfer.value,
              ),
            );

        // Act
        final profitLoss = await repository.calculateProfitLoss(2025);

        // Assert
        expect(profitLoss, 4500.0); // Profit of 4500
      },
    );

    test(
      'calculateProfitLoss - should only count rent and lateFee payments',
      () async {
        // Arrange
        final propertyIds = await seedTestProperties(db);
        final tenantIds = await seedTestTenants(db);
        final contractIds = await seedTestContracts(db, propertyIds, tenantIds);

        // Add 2025 expenses
        await repository.addExpense(
          propertyId: propertyIds[0],
          amount: 1000.0,
          category: ExpenseCategory.maintenance,
          date: DateTime(2025, 6, 15),
          description: 'Maintenance',
        );

        // Add rent payment (should count)
        await db
            .into(db.payments)
            .insert(
              PaymentsCompanion.insert(
                contractId: contractIds[0],
                amount: 3000.0,
                paidDate: DateTime(2025, 6, 1),
                dueDate: DateTime(2025, 6, 1),
                paymentType: PaymentType.rent.value,
                paymentMethod: PaymentMethod.bankTransfer.value,
              ),
            );

        // Add deposit payment (should NOT count as income)
        await db
            .into(db.payments)
            .insert(
              PaymentsCompanion.insert(
                contractId: contractIds[0],
                amount: 5000.0,
                paidDate: DateTime(2025, 1, 1),
                dueDate: DateTime(2025, 1, 1),
                paymentType: PaymentType.deposit.value,
                paymentMethod: PaymentMethod.bankTransfer.value,
              ),
            );

        // Act
        final profitLoss = await repository.calculateProfitLoss(2025);

        // Assert
        expect(profitLoss, 2000.0); // Only rent (3000) - expenses (1000)
      },
    );

    test(
      'calculateProfitLoss - should return 0 when no income or expenses',
      () async {
        // Act
        final profitLoss = await repository.calculateProfitLoss(2025);

        // Assert
        expect(profitLoss, 0.0);
      },
    );
  });

  group('ExpenseRepository - Edge Cases', () {
    test('addExpense - should handle zero amount', () async {
      // Arrange
      final propertyIds = await seedTestProperties(db);

      // Act
      final expense = await repository.addExpense(
        propertyId: propertyIds[0],
        amount: 0.0,
        category: ExpenseCategory.other,
        date: DateTime.now(),
        description: 'Zero amount expense',
      );

      // Assert
      expect(expense.amount, 0.0);
    });

    test('addExpense - should handle large amounts', () async {
      // Arrange
      final propertyIds = await seedTestProperties(db);

      // Act
      final expense = await repository.addExpense(
        propertyId: propertyIds[0],
        amount: 999999.99,
        category: ExpenseCategory.repair,
        date: DateTime.now(),
        description: 'Major renovation',
      );

      // Assert
      expect(expense.amount, 999999.99);
    });

    test('addExpense - should handle unicode in description', () async {
      // Arrange
      final propertyIds = await seedTestProperties(db);

      // Act
      final expense = await repository.addExpense(
        propertyId: propertyIds[0],
        amount: 500.0,
        category: ExpenseCategory.maintenance,
        date: DateTime.now(),
        description: '维修空调系统',
      );

      // Assert
      expect(expense.description, '维修空调系统');
    });

    test('calculateYearlyExpenses - should handle future years', () async {
      // Act
      final total = await repository.calculateYearlyExpenses(2099);

      // Assert
      expect(total, 0.0);
    });
  });
}
