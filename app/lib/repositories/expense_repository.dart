/// Repository for expense-related database operations
///
/// Provides CRUD operations and business logic for property expenses
library;

import 'package:drift/drift.dart';

import '../core/database/app_database.dart';
import '../core/enums/enums.dart';

/// Repository for managing property expenses
class ExpenseRepository {
  final AppDatabase _db;

  ExpenseRepository(this._db);

  // ==========================================================================
  // CRUD OPERATIONS
  // ==========================================================================

  /// Creates a new expense
  ///
  /// Returns the created [Expense] with generated ID
  /// Throws exception if property does not exist (foreign key constraint)
  Future<Expense> addExpense({
    required int propertyId,
    required double amount,
    required ExpenseCategory category,
    required DateTime date,
    required String description,
    String? notes,
  }) async {
    try {
      final id = await _db
          .into(_db.expenses)
          .insert(
            ExpensesCompanion.insert(
              propertyId: propertyId,
              amount: amount,
              category: category.value,
              description: description,
              date: date,
            ),
          );

      final expense = await (_db.select(
        _db.expenses,
      )..where((t) => t.id.equals(id))).getSingle();

      return expense;
    } catch (e) {
      throw Exception('Failed to add expense: $e');
    }
  }

  /// Retrieves all expenses
  ///
  /// Returns empty list if no expenses exist
  Future<List<Expense>> getAllExpenses() async {
    try {
      return await _db.select(_db.expenses).get();
    } catch (e) {
      throw Exception('Failed to get all expenses: $e');
    }
  }

  /// Retrieves expenses for a specific property
  ///
  /// Returns expenses ordered by date (most recent first)
  /// Returns empty list if no expenses exist for the property
  Future<List<Expense>> getExpensesByProperty(int propertyId) async {
    try {
      return await (_db.select(_db.expenses)
            ..where((t) => t.propertyId.equals(propertyId))
            ..orderBy([(t) => OrderingTerm.desc(t.date)]))
          .get();
    } catch (e) {
      throw Exception('Failed to get expenses by property: $e');
    }
  }

  // ==========================================================================
  // BUSINESS LOGIC METHODS
  // ==========================================================================

  /// Calculates total expenses for a given year
  ///
  /// Sums all expense amounts where the expense date falls within the year
  /// Returns 0.0 if no expenses exist for the year
  Future<double> calculateYearlyExpenses(int year) async {
    try {
      final startDate = DateTime(year, 1, 1);
      final endDate = DateTime(year + 1, 1, 1);

      final query = _db.selectOnly(_db.expenses)
        ..addColumns([_db.expenses.amount.sum()])
        ..where(
          _db.expenses.date.isBiggerOrEqualValue(startDate) &
              _db.expenses.date.isSmallerThanValue(endDate),
        );

      final result = await query.getSingle();
      final sum = result.read(_db.expenses.amount.sum());

      return sum ?? 0.0;
    } catch (e) {
      throw Exception('Failed to calculate yearly expenses: $e');
    }
  }

  /// Calculates profit/loss for a given year
  ///
  /// Profit/Loss = Total Income - Total Expenses
  ///
  /// Income includes:
  /// - Rent payments (PaymentType.rent)
  /// - Late fees (PaymentType.lateFee)
  ///
  /// Income excludes:
  /// - Deposits (PaymentType.deposit) - not considered income
  /// - Deposit returns (PaymentType.depositReturn) - actual expense
  ///
  /// Returns:
  /// - Positive value = profit
  /// - Negative value = loss
  /// - 0.0 if no income or expenses
  Future<double> calculateProfitLoss(int year) async {
    try {
      final startDate = DateTime(year, 1, 1);
      final endDate = DateTime(year + 1, 1, 1);

      // Calculate total expenses
      final expensesTotal = await calculateYearlyExpenses(year);

      // Calculate total income (rent + late fees only)
      final incomeQuery = _db.selectOnly(_db.payments)
        ..addColumns([_db.payments.amount.sum()])
        ..where(
          _db.payments.paidDate.isBiggerOrEqualValue(startDate) &
              _db.payments.paidDate.isSmallerThanValue(endDate) &
              (_db.payments.paymentType.equals(PaymentType.rent.value) |
                  _db.payments.paymentType.equals(PaymentType.lateFee.value)),
        );

      final incomeResult = await incomeQuery.getSingle();
      final incomeTotal = incomeResult.read(_db.payments.amount.sum()) ?? 0.0;

      // Profit/Loss = Income - Expenses
      return incomeTotal - expensesTotal;
    } catch (e) {
      throw Exception('Failed to calculate profit/loss: $e');
    }
  }
}
