/// Test helper for database operations
///
/// Provides utilities for creating test databases and seeding test data
library;

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import '../../lib/core/database/app_database.dart';
import '../../lib/core/enums/enums.dart';

// ==============================================================================
// DATABASE HELPER
// ==============================================================================

/// Creates an in-memory test database
///
/// Each test should create its own isolated database instance
/// to prevent test interference.
AppDatabase createTestDatabase() {
  return AppDatabase.forTesting(NativeDatabase.memory());
}

// ==============================================================================
// TEST DATA SEEDING
// ==============================================================================

/// Seeds the database with test properties
///
/// Returns the list of created property IDs
Future<List<int>> seedTestProperties(AppDatabase db) async {
  final ids = <int>[];

  ids.add(await db.into(db.properties).insert(
        PropertiesCompanion.insert(
          name: 'Apartment 101',
          address: '123 Main St',
          propertyType: PropertyType.residential.value,
        ),
      ));

  ids.add(await db.into(db.properties).insert(
        PropertiesCompanion.insert(
          name: 'Office Suite 200',
          address: '456 Business Ave',
          propertyType: PropertyType.commercial.value,
        ),
      ));

  ids.add(await db.into(db.properties).insert(
        PropertiesCompanion.insert(
          name: 'Apartment 102',
          address: '123 Main St',
          propertyType: PropertyType.residential.value,
        ),
      ));

  return ids;
}

/// Seeds the database with test tenants
///
/// Returns the list of created tenant IDs
Future<List<int>> seedTestTenants(AppDatabase db) async {
  final ids = <int>[];

  ids.add(await db.into(db.tenants).insert(
        TenantsCompanion.insert(
          name: 'John Doe',
          phone: '1234567890',
          email: const Value('john@example.com'),
        ),
      ));

  ids.add(await db.into(db.tenants).insert(
        TenantsCompanion.insert(
          name: 'Jane Smith',
          phone: '0987654321',
          email: const Value('jane@example.com'),
        ),
      ));

  ids.add(await db.into(db.tenants).insert(
        TenantsCompanion.insert(
          name: 'Bob Johnson',
          phone: '5555555555',
          email: const Value(null),
        ),
      ));

  return ids;
}

/// Seeds the database with test contracts
///
/// Requires [propertyIds] and [tenantIds] from previous seeding
/// Returns the list of created contract IDs
Future<List<int>> seedTestContracts(
  AppDatabase db,
  List<int> propertyIds,
  List<int> tenantIds,
) async {
  final ids = <int>[];
  final now = DateTime.now();

  // Active contract for Apartment 101
  ids.add(await db.into(db.contracts).insert(
        ContractsCompanion.insert(
          propertyId: propertyIds[0],
          tenantId: tenantIds[0],
          startDate: now.subtract(const Duration(days: 30)),
          endDate: now.add(const Duration(days: 335)),
          rentAmount: 1000.0,
          paymentCycle: PaymentCycle.monthly.value,
          depositAmount: 2000.0,
          isActive: const Value(true),
        ),
      ));

  // Active contract for Office Suite 200
  ids.add(await db.into(db.contracts).insert(
        ContractsCompanion.insert(
          propertyId: propertyIds[1],
          tenantId: tenantIds[1],
          startDate: now.subtract(const Duration(days: 60)),
          endDate: now.add(const Duration(days: 305)),
          rentAmount: 3000.0,
          paymentCycle: PaymentCycle.quarterly.value,
          depositAmount: 6000.0,
          isActive: const Value(true),
        ),
      ));

  // Inactive (expired) contract for Apartment 102
  ids.add(await db.into(db.contracts).insert(
        ContractsCompanion.insert(
          propertyId: propertyIds[2],
          tenantId: tenantIds[2],
          startDate: now.subtract(const Duration(days: 400)),
          endDate: now.subtract(const Duration(days: 35)),
          rentAmount: 800.0,
          paymentCycle: PaymentCycle.monthly.value,
          depositAmount: 1600.0,
          isActive: const Value(false),
        ),
      ));

  return ids;
}

/// Seeds the database with test expenses
///
/// Requires [propertyIds] from previous seeding
/// Returns the list of created expense IDs
Future<List<int>> seedTestExpenses(
  AppDatabase db,
  List<int> propertyIds,
) async {
  final ids = <int>[];
  final now = DateTime.now();

  // Maintenance expense for Apartment 101
  ids.add(await db.into(db.expenses).insert(
        ExpensesCompanion.insert(
          propertyId: propertyIds[0],
          amount: 200.0,
          category: ExpenseCategory.maintenance.value,
          description: 'Monthly cleaning',
          date: now.subtract(const Duration(days: 15)),
        ),
      ));

  // Repair expense for Office Suite 200
  ids.add(await db.into(db.expenses).insert(
        ExpensesCompanion.insert(
          propertyId: propertyIds[1],
          amount: 1500.0,
          category: ExpenseCategory.repair.value,
          description: 'HVAC repair',
          date: now.subtract(const Duration(days: 30)),
        ),
      ));

  // Other expense for Apartment 102
  ids.add(await db.into(db.expenses).insert(
        ExpensesCompanion.insert(
          propertyId: propertyIds[2],
          amount: 100.0,
          category: ExpenseCategory.other.value,
          description: 'Property tax',
          date: now.subtract(const Duration(days: 45)),
        ),
      ));

  return ids;
}

/// Seeds the database with test payment schedules
///
/// Requires [contractIds] from previous seeding
/// Returns the list of created schedule IDs
Future<List<int>> seedTestPaymentSchedules(
  AppDatabase db,
  List<int> contractIds,
) async {
  final ids = <int>[];
  final now = DateTime.now();

  // Paid schedule for first contract
  ids.add(await db.into(db.paymentSchedules).insert(
        PaymentSchedulesCompanion.insert(
          contractId: contractIds[0],
          dueDate: now.subtract(const Duration(days: 30)),
          amount: 1000.0,
          isPaid: const Value(true),
          paidDate: Value(now.subtract(const Duration(days: 30))),
        ),
      ));

  // Overdue schedule for first contract
  ids.add(await db.into(db.paymentSchedules).insert(
        PaymentSchedulesCompanion.insert(
          contractId: contractIds[0],
          dueDate: now.subtract(const Duration(days: 5)),
          amount: 1000.0,
          isPaid: const Value(false),
        ),
      ));

  // Upcoming schedule for first contract
  ids.add(await db.into(db.paymentSchedules).insert(
        PaymentSchedulesCompanion.insert(
          contractId: contractIds[0],
          dueDate: now.add(const Duration(days: 25)),
          amount: 1000.0,
          isPaid: const Value(false),
        ),
      ));

  // Paid schedule for second contract
  ids.add(await db.into(db.paymentSchedules).insert(
        PaymentSchedulesCompanion.insert(
          contractId: contractIds[1],
          dueDate: now.subtract(const Duration(days: 60)),
          amount: 3000.0,
          isPaid: const Value(true),
          paidDate: Value(now.subtract(const Duration(days: 58))),
        ),
      ));

  return ids;
}

/// Seeds the database with test payments
///
/// Requires [contractIds] from previous seeding
/// Returns the list of created payment IDs
Future<List<int>> seedTestPayments(
  AppDatabase db,
  List<int> contractIds,
) async {
  final ids = <int>[];
  final now = DateTime.now();

  // Rent payment for first contract
  ids.add(await db.into(db.payments).insert(
        PaymentsCompanion.insert(
          contractId: contractIds[0],
          amount: 1000.0,
          paidDate: now.subtract(const Duration(days: 30)),
          dueDate: now.subtract(const Duration(days: 30)),
          paymentType: PaymentType.rent.value,
          paymentMethod: PaymentMethod.bankTransfer.value,
          isPartial: const Value(false),
        ),
      ));

  // Deposit payment for first contract
  ids.add(await db.into(db.payments).insert(
        PaymentsCompanion.insert(
          contractId: contractIds[0],
          amount: 2000.0,
          paidDate: now.subtract(const Duration(days: 60)),
          dueDate: now.subtract(const Duration(days: 60)),
          paymentType: PaymentType.deposit.value,
          paymentMethod: PaymentMethod.bankTransfer.value,
          isPartial: const Value(false),
        ),
      ));

  // Partial rent payment for second contract
  ids.add(await db.into(db.payments).insert(
        PaymentsCompanion.insert(
          contractId: contractIds[1],
          amount: 1500.0,
          paidDate: now.subtract(const Duration(days: 58)),
          dueDate: now.subtract(const Duration(days: 60)),
          paymentType: PaymentType.rent.value,
          paymentMethod: PaymentMethod.wechatPay.value,
          isPartial: const Value(true),
          notes: const Value('Partial payment - remaining balance pending'),
        ),
      ));

  return ids;
}

/// Seeds the database with complete test data
///
/// Creates properties, tenants, contracts, expenses, payment schedules, and payments
/// Returns a map with all created IDs
Future<Map<String, List<int>>> seedCompleteTestData(AppDatabase db) async {
  final propertyIds = await seedTestProperties(db);
  final tenantIds = await seedTestTenants(db);
  final contractIds = await seedTestContracts(db, propertyIds, tenantIds);
  final expenseIds = await seedTestExpenses(db, propertyIds);
  final scheduleIds = await seedTestPaymentSchedules(db, contractIds);
  final paymentIds = await seedTestPayments(db, contractIds);

  return {
    'properties': propertyIds,
    'tenants': tenantIds,
    'contracts': contractIds,
    'expenses': expenseIds,
    'schedules': scheduleIds,
    'payments': paymentIds,
  };
}
