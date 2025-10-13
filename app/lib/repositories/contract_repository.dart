/// Repository for contract-related database operations
///
/// Provides CRUD operations and payment schedule generation for rental contracts
library;

import 'package:drift/drift.dart';

import '../core/database/app_database.dart';
import '../core/enums/enums.dart';

/// Repository for managing rental contracts
class ContractRepository {
  final AppDatabase _db;

  ContractRepository(this._db);

  // ==========================================================================
  // CRUD OPERATIONS
  // ==========================================================================

  /// Creates a new rental contract
  ///
  /// Returns the created [Contract] with generated ID
  /// Throws exception if property or tenant does not exist (foreign key constraints)
  Future<Contract> createContract({
    required int propertyId,
    required int tenantId,
    required DateTime startDate,
    required DateTime endDate,
    required double rentAmount,
    required PaymentCycle cycle,
    required double depositAmount,
  }) async {
    try {
      final id = await _db.into(_db.contracts).insert(
            ContractsCompanion.insert(
              propertyId: propertyId,
              tenantId: tenantId,
              startDate: startDate,
              endDate: endDate,
              rentAmount: rentAmount,
              paymentCycle: cycle.value,
              depositAmount: depositAmount,
              isActive: const Value(true),
            ),
          );

      final contract = await (_db.select(_db.contracts)
            ..where((t) => t.id.equals(id)))
          .getSingle();

      return contract;
    } catch (e) {
      throw Exception('Failed to create contract: $e');
    }
  }

  /// Retrieves all contracts
  ///
  /// Returns empty list if no contracts exist
  Future<List<Contract>> getAllContracts() async {
    try {
      return await _db.select(_db.contracts).get();
    } catch (e) {
      throw Exception('Failed to get all contracts: $e');
    }
  }

  /// Retrieves only active contracts
  ///
  /// Returns empty list if no active contracts exist
  Future<List<Contract>> getActiveContracts() async {
    try {
      return await (_db.select(_db.contracts)
            ..where((t) => t.isActive.equals(true)))
          .get();
    } catch (e) {
      throw Exception('Failed to get active contracts: $e');
    }
  }

  /// Retrieves a contract by ID
  ///
  /// Returns null if contract does not exist
  Future<Contract?> getContractById(int id) async {
    try {
      final query = _db.select(_db.contracts)..where((t) => t.id.equals(id));
      final results = await query.get();
      return results.isEmpty ? null : results.first;
    } catch (e) {
      throw Exception('Failed to get contract by id: $e');
    }
  }

  /// Updates an existing contract
  ///
  /// Updates the updatedAt timestamp automatically
  /// Throws exception if contract does not exist
  Future<void> updateContract(Contract contract) async {
    try {
      final updatedContract = contract.copyWith(
        updatedAt: DateTime.now(),
      );

      final rowsAffected = await (_db.update(_db.contracts)
            ..where((t) => t.id.equals(contract.id)))
          .write(
        ContractsCompanion(
          propertyId: Value(updatedContract.propertyId),
          tenantId: Value(updatedContract.tenantId),
          startDate: Value(updatedContract.startDate),
          endDate: Value(updatedContract.endDate),
          rentAmount: Value(updatedContract.rentAmount),
          paymentCycle: Value(updatedContract.paymentCycle),
          depositAmount: Value(updatedContract.depositAmount),
          isActive: Value(updatedContract.isActive),
          updatedAt: Value(updatedContract.updatedAt),
        ),
      );

      if (rowsAffected == 0) {
        throw Exception('Contract with id ${contract.id} not found');
      }
    } catch (e) {
      throw Exception('Failed to update contract: $e');
    }
  }

  /// Terminates a contract by marking it as inactive
  ///
  /// Throws exception if contract does not exist
  Future<void> terminateContract(int id) async {
    try {
      final rowsAffected = await (_db.update(_db.contracts)
            ..where((t) => t.id.equals(id)))
          .write(
        ContractsCompanion(
          isActive: const Value(false),
          updatedAt: Value(DateTime.now()),
        ),
      );

      if (rowsAffected == 0) {
        throw Exception('Contract with id $id not found');
      }
    } catch (e) {
      throw Exception('Failed to terminate contract: $e');
    }
  }

  // ==========================================================================
  // PAYMENT SCHEDULE GENERATION
  // ==========================================================================

  /// Generates payment schedules for a contract
  ///
  /// Creates a series of payment schedules based on the payment cycle
  /// from startDate to endDate (inclusive).
  ///
  /// Examples:
  /// - Monthly: 12 schedules for a 1-year contract
  /// - Quarterly: 4 schedules for a 1-year contract
  /// - Yearly: 1 schedule for a 1-year contract
  ///
  /// Handles edge cases:
  /// - Mid-month start dates (e.g., Jan 15 -> Feb 15 -> Mar 15...)
  /// - Month-end dates (e.g., Jan 31 -> Feb 28 -> Mar 31...)
  /// - Multi-year contracts
  ///
  /// Returns list of created [PaymentSchedule] objects
  /// Throws exception if contract does not exist
  Future<List<PaymentSchedule>> generatePaymentSchedules(
    int contractId,
    DateTime startDate,
    DateTime endDate,
    PaymentCycle cycle,
    double amount,
  ) async {
    try {
      // Verify contract exists
      final contract = await getContractById(contractId);
      if (contract == null) {
        throw Exception('Contract with id $contractId not found');
      }

      final schedules = <PaymentSchedule>[];
      DateTime currentDate = startDate;

      // Generate schedules until we exceed the end date
      while (currentDate.isBefore(endDate) ||
          currentDate.isAtSameMomentAs(endDate)) {
        // Create schedule for current date
        final scheduleId = await _db.into(_db.paymentSchedules).insert(
              PaymentSchedulesCompanion.insert(
                contractId: contractId,
                dueDate: currentDate,
                amount: amount,
                isPaid: const Value(false),
              ),
            );

        final schedule = await (_db.select(_db.paymentSchedules)
              ..where((t) => t.id.equals(scheduleId)))
            .getSingle();

        schedules.add(schedule);

        // Calculate next payment date based on cycle
        currentDate = _addMonths(currentDate, cycle.months);
      }

      return schedules;
    } catch (e) {
      throw Exception('Failed to generate payment schedules: $e');
    }
  }

  /// Adds months to a date, handling edge cases
  ///
  /// Handles month-end dates correctly by clamping to the last valid day:
  /// - Jan 31 + 1 month = Feb 28 (or 29 in leap year)
  /// - Feb 28 + 1 month = Mar 31 (goes back to day 31 if target month has it)
  /// - Jan 31 + 2 months = Mar 31
  DateTime _addMonths(DateTime date, int months) {
    // Calculate target month and year
    var targetMonth = date.month + months;
    var targetYear = date.year;

    // Handle year overflow/underflow
    while (targetMonth > 12) {
      targetMonth -= 12;
      targetYear++;
    }
    while (targetMonth < 1) {
      targetMonth += 12;
      targetYear--;
    }

    // Get the maximum day in the target month
    final daysInTargetMonth = _daysInMonth(targetYear, targetMonth);

    // Clamp the day to the valid range
    final targetDay = date.day > daysInTargetMonth ? daysInTargetMonth : date.day;

    return DateTime(
      targetYear,
      targetMonth,
      targetDay,
      date.hour,
      date.minute,
      date.second,
      date.millisecond,
      date.microsecond,
    );
  }

  /// Returns the number of days in a given month
  int _daysInMonth(int year, int month) {
    // Create a date for the first day of the next month, then subtract 1 day
    final nextMonth = month == 12 ? DateTime(year + 1, 1, 1) : DateTime(year, month + 1, 1);
    final lastDayOfMonth = nextMonth.subtract(const Duration(days: 1));
    return lastDayOfMonth.day;
  }
}
