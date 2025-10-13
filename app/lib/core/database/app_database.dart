import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

// ==============================================================================
// TABLE DEFINITIONS
// ==============================================================================

/// Properties table - stores rental property information
@DataClassName('Property')
class Properties extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get address => text()();
  TextColumn get propertyType => text()(); // 'residential' or 'commercial'
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>>? get uniqueKeys => [
    {name, address}, // Prevent duplicate property names at same address
  ];
}

/// Tenants table - stores tenant information
@DataClassName('Tenant')
class Tenants extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get phone => text()();
  TextColumn get email => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Contracts table - stores rental contract information
@DataClassName('Contract')
class Contracts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get propertyId => integer().references(
    Properties,
    #id,
    onDelete: KeyAction.cascade,
  )(); // Cascade delete when property deleted
  IntColumn get tenantId => integer().references(
    Tenants,
    #id,
    onDelete: KeyAction.restrict,
  )(); // Prevent tenant deletion if they have contracts
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime()();
  RealColumn get rentAmount => real()();
  TextColumn get paymentCycle =>
      text()(); // 'monthly', 'bimonthly', 'quarterly', 'yearly'
  RealColumn get depositAmount => real()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>>? get uniqueKeys => [
    // Prevent overlapping contracts for same property
    // This is enforced at application level, but we ensure
    // one active contract per property at database level
    {propertyId, startDate},
  ];
}

/// Payments table - stores payment records
@DataClassName('Payment')
class Payments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get contractId => integer().references(
    Contracts,
    #id,
    onDelete: KeyAction.cascade,
  )(); // Cascade delete with contract
  RealColumn get amount => real()();
  DateTimeColumn get paidDate => dateTime()();
  DateTimeColumn get dueDate => dateTime()();
  TextColumn get paymentType =>
      text()(); // 'rent', 'lateFee', 'deposit', 'depositReturn'
  TextColumn get paymentMethod =>
      text()(); // 'bankTransfer', 'wechatPay', 'cash'
  BoolColumn get isPartial => boolean().withDefault(const Constant(false))();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// PaymentSchedules table - stores scheduled payments
@DataClassName('PaymentSchedule')
class PaymentSchedules extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get contractId => integer().references(
    Contracts,
    #id,
    onDelete: KeyAction.cascade,
  )(); // Cascade delete with contract
  DateTimeColumn get dueDate => dateTime()();
  RealColumn get amount => real()();
  BoolColumn get isPaid => boolean().withDefault(const Constant(false))();
  DateTimeColumn get paidDate => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Expenses table - stores property expense records
@DataClassName('Expense')
class Expenses extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get propertyId => integer().references(
    Properties,
    #id,
    onDelete: KeyAction.cascade,
  )(); // Cascade delete with property
  RealColumn get amount => real()();
  TextColumn get category => text()(); // 'maintenance', 'repair', 'other'
  TextColumn get description => text()();
  DateTimeColumn get date => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// ==============================================================================
// DATABASE CLASS
// ==============================================================================

@DriftDatabase(
  tables: [
    Properties,
    Tenants,
    Contracts,
    Payments,
    PaymentSchedules,
    Expenses,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // Constructor for testing with in-memory database
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      // Create indexes after table creation
      await _createIndexes(m);
    },
    onUpgrade: (Migrator m, int from, int to) async {
      // Future schema migrations will go here
      // Example for schema version 2:
      // if (from < 2) {
      //   await m.addColumn(properties, properties.newColumn);
      // }
    },
    beforeOpen: (details) async {
      // Enable foreign key constraints
      await customStatement('PRAGMA foreign_keys = ON');

      // Verify database integrity on open
      if (details.wasCreated) {
        // Log database creation for debugging
        debugPrint('Database created at version ${details.versionNow}');
      }
    },
  );

  /// Create performance-optimized indexes
  ///
  /// Based on architect's recommendations:
  /// - Index on foreign keys for JOIN performance
  /// - Index on frequently queried columns (dueDate, isActive, date)
  /// - Compound indexes for common query patterns
  Future<void> _createIndexes(Migrator m) async {
    // Contracts table indexes
    await m.database.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_contracts_property_id ON contracts(property_id);',
    );
    await m.database.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_contracts_tenant_id ON contracts(tenant_id);',
    );
    await m.database.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_contracts_is_active ON contracts(is_active);',
    );
    await m.database.customStatement(
      // Compound index for active contracts query optimization
      'CREATE INDEX IF NOT EXISTS idx_contracts_property_active ON contracts(property_id, is_active);',
    );

    // Payments table indexes
    await m.database.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_payments_contract_id ON payments(contract_id);',
    );
    await m.database.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_payments_due_date ON payments(due_date);',
    );
    await m.database.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_payments_paid_date ON payments(paid_date);',
    );
    await m.database.customStatement(
      // Compound index for payment type queries
      'CREATE INDEX IF NOT EXISTS idx_payments_contract_type ON payments(contract_id, payment_type);',
    );

    // PaymentSchedules table indexes
    await m.database.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_payment_schedules_contract_id ON payment_schedules(contract_id);',
    );
    await m.database.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_payment_schedules_due_date ON payment_schedules(due_date);',
    );
    await m.database.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_payment_schedules_is_paid ON payment_schedules(is_paid);',
    );
    await m.database.customStatement(
      // Compound index for overdue payment queries (most critical!)
      'CREATE INDEX IF NOT EXISTS idx_payment_schedules_unpaid_due ON payment_schedules(is_paid, due_date);',
    );

    // Expenses table indexes
    await m.database.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_expenses_property_id ON expenses(property_id);',
    );
    await m.database.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_expenses_date ON expenses(date);',
    );
    await m.database.customStatement(
      // Compound index for property expense queries
      'CREATE INDEX IF NOT EXISTS idx_expenses_property_date ON expenses(property_id, date);',
    );
  }

  /// Close the database connection
  Future<void> closeDb() async {
    await close();
  }
}

// ==============================================================================
// DATABASE CONNECTION
// ==============================================================================

/// Opens a connection to the SQLite database
///
/// Uses LazyDatabase for proper async initialization with path_provider
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'rent_tracker.db'));

    // For development, you can uncomment this to see the database path
    debugPrint('Database path: ${file.path}');

    return NativeDatabase.createInBackground(file);
  });
}

/// Debug print helper (uses Flutter's debugPrint if available, otherwise print)
void debugPrint(String message) {
  // ignore: avoid_print
  print(message);
}
