import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_tracker/core/database/app_database.dart';

void main() {
  late AppDatabase database;

  /// Create an in-memory database for testing
  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  /// Close database after each test
  tearDown(() async {
    await database.close();
  });

  group('Database Initialization Tests', () {
    test('database should initialize successfully', () async {
      // Arrange & Act
      // Database is initialized in setUp()

      // Assert - Verify database is open and accessible
      expect(database, isNotNull);
      expect(database.schemaVersion, equals(1));
    });

    test('should create all 6 tables successfully', () async {
      // Arrange & Act
      // Tables are created automatically on database initialization

      // Assert - Verify we can query each table (even if empty)
      final properties = await database.select(database.properties).get();
      final tenants = await database.select(database.tenants).get();
      final contracts = await database.select(database.contracts).get();
      final payments = await database.select(database.payments).get();
      final paymentSchedules = await database
          .select(database.paymentSchedules)
          .get();
      final expenses = await database.select(database.expenses).get();

      expect(properties, isEmpty);
      expect(tenants, isEmpty);
      expect(contracts, isEmpty);
      expect(payments, isEmpty);
      expect(paymentSchedules, isEmpty);
      expect(expenses, isEmpty);
    });

    test('should have foreign key constraints enabled', () async {
      // Arrange & Act
      final result = await database.customSelect('PRAGMA foreign_keys').get();

      // Assert
      expect(result.first.data['foreign_keys'], equals(1));
    });
  });

  group('Table Structure Tests', () {
    test('Properties table should have all required columns', () async {
      // Arrange & Act
      final tableInfo = await database
          .customSelect('PRAGMA table_info(properties)')
          .get();

      // Assert
      final columnNames = tableInfo.map((row) => row.data['name']).toList();
      expect(columnNames, contains('id'));
      expect(columnNames, contains('name'));
      expect(columnNames, contains('address'));
      expect(columnNames, contains('property_type'));
      expect(columnNames, contains('created_at'));
      expect(columnNames, contains('updated_at'));
    });

    test('Contracts table should have all required columns', () async {
      // Arrange & Act
      final tableInfo = await database
          .customSelect('PRAGMA table_info(contracts)')
          .get();

      // Assert
      final columnNames = tableInfo.map((row) => row.data['name']).toList();
      expect(columnNames, contains('id'));
      expect(columnNames, contains('property_id'));
      expect(columnNames, contains('tenant_id'));
      expect(columnNames, contains('start_date'));
      expect(columnNames, contains('end_date'));
      expect(columnNames, contains('rent_amount'));
      expect(columnNames, contains('payment_cycle'));
      expect(columnNames, contains('deposit_amount'));
      expect(columnNames, contains('is_active'));
      expect(columnNames, contains('created_at'));
      expect(columnNames, contains('updated_at'));
    });

    test('PaymentSchedules table should have all required columns', () async {
      // Arrange & Act
      final tableInfo = await database
          .customSelect('PRAGMA table_info(payment_schedules)')
          .get();

      // Assert
      final columnNames = tableInfo.map((row) => row.data['name']).toList();
      expect(columnNames, contains('id'));
      expect(columnNames, contains('contract_id'));
      expect(columnNames, contains('due_date'));
      expect(columnNames, contains('amount'));
      expect(columnNames, contains('is_paid'));
      expect(columnNames, contains('paid_date'));
      expect(columnNames, contains('created_at'));
      expect(columnNames, contains('updated_at'));
    });
  });

  group('Foreign Key Constraint Tests', () {
    test(
      'should enforce foreign key constraint: Contracts -> Properties',
      () async {
        // Arrange - Try to insert contract without property
        final invalidContract = ContractsCompanion(
          propertyId: const Value(999), // Non-existent property ID
          tenantId: const Value(1),
          startDate: Value(DateTime.now()),
          endDate: Value(DateTime.now().add(const Duration(days: 365))),
          rentAmount: const Value(1000.0),
          paymentCycle: const Value('monthly'),
          depositAmount: const Value(2000.0),
        );

        // Act & Assert - Should throw foreign key constraint error
        expect(
          () => database.into(database.contracts).insert(invalidContract),
          throwsA(isA<SqliteException>()),
        );
      },
    );

    test(
      'should enforce foreign key constraint: Payments -> Contracts',
      () async {
        // Arrange - Try to insert payment without contract
        final invalidPayment = PaymentsCompanion(
          contractId: const Value(999), // Non-existent contract ID
          amount: const Value(1000.0),
          paidDate: Value(DateTime.now()),
          dueDate: Value(DateTime.now()),
          paymentType: const Value('rent'),
          paymentMethod: const Value('bankTransfer'),
        );

        // Act & Assert
        expect(
          () => database.into(database.payments).insert(invalidPayment),
          throwsA(isA<SqliteException>()),
        );
      },
    );

    test('should cascade delete: Property -> Contracts -> Payments', () async {
      // Arrange - Create property -> contract -> payment chain
      final propertyId = await database
          .into(database.properties)
          .insert(
            PropertiesCompanion(
              name: const Value('Test Property'),
              address: const Value('123 Test St'),
              propertyType: const Value('residential'),
            ),
          );

      final tenantId = await database
          .into(database.tenants)
          .insert(
            TenantsCompanion(
              name: const Value('Test Tenant'),
              phone: const Value('1234567890'),
            ),
          );

      final contractId = await database
          .into(database.contracts)
          .insert(
            ContractsCompanion(
              propertyId: Value(propertyId),
              tenantId: Value(tenantId),
              startDate: Value(DateTime.now()),
              endDate: Value(DateTime.now().add(const Duration(days: 365))),
              rentAmount: const Value(1000.0),
              paymentCycle: const Value('monthly'),
              depositAmount: const Value(2000.0),
            ),
          );

      await database
          .into(database.payments)
          .insert(
            PaymentsCompanion(
              contractId: Value(contractId),
              amount: const Value(1000.0),
              paidDate: Value(DateTime.now()),
              dueDate: Value(DateTime.now()),
              paymentType: const Value('rent'),
              paymentMethod: const Value('bankTransfer'),
            ),
          );

      // Act - Delete the property
      await (database.delete(
        database.properties,
      )..where((tbl) => tbl.id.equals(propertyId))).go();

      // Assert - Verify cascade deletion
      final contracts = await database.select(database.contracts).get();
      final payments = await database.select(database.payments).get();

      expect(contracts, isEmpty); // Contract should be cascade deleted
      expect(payments, isEmpty); // Payment should be cascade deleted
    });

    test('should restrict delete: Tenant with active contracts', () async {
      // Arrange - Create tenant with contract
      final tenantId = await database
          .into(database.tenants)
          .insert(
            TenantsCompanion(
              name: const Value('Test Tenant'),
              phone: const Value('1234567890'),
            ),
          );

      final propertyId = await database
          .into(database.properties)
          .insert(
            PropertiesCompanion(
              name: const Value('Test Property'),
              address: const Value('123 Test St'),
              propertyType: const Value('residential'),
            ),
          );

      await database
          .into(database.contracts)
          .insert(
            ContractsCompanion(
              propertyId: Value(propertyId),
              tenantId: Value(tenantId),
              startDate: Value(DateTime.now()),
              endDate: Value(DateTime.now().add(const Duration(days: 365))),
              rentAmount: const Value(1000.0),
              paymentCycle: const Value('monthly'),
              depositAmount: const Value(2000.0),
            ),
          );

      // Act & Assert - Should throw foreign key constraint error
      expect(
        () => (database.delete(
          database.tenants,
        )..where((tbl) => tbl.id.equals(tenantId))).go(),
        throwsA(isA<SqliteException>()),
      );
    });
  });

  group('Index Creation Tests', () {
    test('should have indexes created for performance optimization', () async {
      // Arrange & Act
      final indexes = await database
          .customSelect("SELECT name FROM sqlite_master WHERE type='index'")
          .get();

      final indexNames = indexes.map((row) => row.data['name']).toList();

      // Assert - Verify critical indexes exist
      expect(indexNames, contains('idx_contracts_property_id'));
      expect(indexNames, contains('idx_contracts_tenant_id'));
      expect(indexNames, contains('idx_contracts_is_active'));
      expect(indexNames, contains('idx_payments_contract_id'));
      expect(indexNames, contains('idx_payments_due_date'));
      expect(indexNames, contains('idx_payment_schedules_contract_id'));
      expect(indexNames, contains('idx_payment_schedules_due_date'));
      expect(indexNames, contains('idx_payment_schedules_is_paid'));
      expect(indexNames, contains('idx_payment_schedules_unpaid_due'));
      expect(indexNames, contains('idx_expenses_property_id'));
    });
  });

  group('Basic CRUD Operations Tests', () {
    test('should insert and retrieve a property', () async {
      // Arrange
      final propertyCompanion = PropertiesCompanion(
        name: const Value('Sunset Apartment'),
        address: const Value('123 Main Street'),
        propertyType: const Value('residential'),
      );

      // Act
      final id = await database
          .into(database.properties)
          .insert(propertyCompanion);
      final properties = await database.select(database.properties).get();

      // Assert
      expect(id, greaterThan(0));
      expect(properties.length, equals(1));
      expect(properties.first.name, equals('Sunset Apartment'));
      expect(properties.first.address, equals('123 Main Street'));
      expect(properties.first.propertyType, equals('residential'));
      expect(properties.first.createdAt, isNotNull);
      expect(properties.first.updatedAt, isNotNull);
    });

    test('should insert and retrieve a tenant', () async {
      // Arrange
      final tenantCompanion = TenantsCompanion(
        name: const Value('John Doe'),
        phone: const Value('+1234567890'),
        email: const Value('john@example.com'),
      );

      // Act
      final id = await database.into(database.tenants).insert(tenantCompanion);
      final tenants = await database.select(database.tenants).get();

      // Assert
      expect(id, greaterThan(0));
      expect(tenants.length, equals(1));
      expect(tenants.first.name, equals('John Doe'));
      expect(tenants.first.phone, equals('+1234567890'));
      expect(tenants.first.email, equals('john@example.com'));
      expect(tenants.first.createdAt, isNotNull);
      expect(tenants.first.updatedAt, isNotNull);
    });

    test('should insert and retrieve a contract with relationships', () async {
      // Arrange - Create property and tenant first
      final propertyId = await database
          .into(database.properties)
          .insert(
            PropertiesCompanion(
              name: const Value('Test Property'),
              address: const Value('456 Oak Ave'),
              propertyType: const Value('commercial'),
            ),
          );

      final tenantId = await database
          .into(database.tenants)
          .insert(
            TenantsCompanion(
              name: const Value('Jane Smith'),
              phone: const Value('+9876543210'),
            ),
          );

      final startDate = DateTime(2025, 1, 1);
      final endDate = DateTime(2025, 12, 31);

      final contractCompanion = ContractsCompanion(
        propertyId: Value(propertyId),
        tenantId: Value(tenantId),
        startDate: Value(startDate),
        endDate: Value(endDate),
        rentAmount: const Value(2500.0),
        paymentCycle: const Value('monthly'),
        depositAmount: const Value(5000.0),
        isActive: const Value(true),
      );

      // Act
      final id = await database
          .into(database.contracts)
          .insert(contractCompanion);
      final contracts = await database.select(database.contracts).get();

      // Assert
      expect(id, greaterThan(0));
      expect(contracts.length, equals(1));
      expect(contracts.first.propertyId, equals(propertyId));
      expect(contracts.first.tenantId, equals(tenantId));
      expect(contracts.first.rentAmount, equals(2500.0));
      expect(contracts.first.paymentCycle, equals('monthly'));
      expect(contracts.first.depositAmount, equals(5000.0));
      expect(contracts.first.isActive, isTrue);
      expect(contracts.first.createdAt, isNotNull);
      expect(contracts.first.updatedAt, isNotNull);
    });

    test('should update a record successfully', () async {
      // Arrange
      final propertyId = await database
          .into(database.properties)
          .insert(
            PropertiesCompanion(
              name: const Value('Old Name'),
              address: const Value('123 Test St'),
              propertyType: const Value('residential'),
            ),
          );

      // Act - Update the property
      await (database.update(database.properties)
            ..where((tbl) => tbl.id.equals(propertyId)))
          .write(const PropertiesCompanion(name: Value('New Name')));

      final updatedProperty = await (database.select(
        database.properties,
      )..where((tbl) => tbl.id.equals(propertyId))).getSingle();

      // Assert
      expect(updatedProperty.name, equals('New Name'));
      expect(
        updatedProperty.address,
        equals('123 Test St'),
      ); // Other fields unchanged
      expect(updatedProperty.propertyType, equals('residential'));
    });

    test('should delete a record successfully', () async {
      // Arrange
      final propertyId = await database
          .into(database.properties)
          .insert(
            PropertiesCompanion(
              name: const Value('To Delete'),
              address: const Value('999 Delete St'),
              propertyType: const Value('residential'),
            ),
          );

      // Act
      final deletedCount = await (database.delete(
        database.properties,
      )..where((tbl) => tbl.id.equals(propertyId))).go();

      final properties = await database.select(database.properties).get();

      // Assert
      expect(deletedCount, equals(1));
      expect(properties, isEmpty);
    });
  });

  group('Default Value Tests', () {
    test('should set default values for createdAt and updatedAt', () async {
      // Arrange & Act
      await database
          .into(database.properties)
          .insert(
            PropertiesCompanion(
              name: const Value('Test Property'),
              address: const Value('123 Test St'),
              propertyType: const Value('residential'),
              // Note: NOT setting createdAt or updatedAt - should use defaults
            ),
          );

      final property = await database.select(database.properties).getSingle();

      // Assert
      expect(property.createdAt, isNotNull);
      expect(property.updatedAt, isNotNull);
      expect(
        property.createdAt.isBefore(
          DateTime.now().add(const Duration(seconds: 1)),
        ),
        isTrue,
      );
    });

    test('should set default value for Contract.isActive to true', () async {
      // Arrange
      final propertyId = await database
          .into(database.properties)
          .insert(
            PropertiesCompanion(
              name: const Value('Test Property'),
              address: const Value('123 Test St'),
              propertyType: const Value('residential'),
            ),
          );

      final tenantId = await database
          .into(database.tenants)
          .insert(
            TenantsCompanion(
              name: const Value('Test Tenant'),
              phone: const Value('1234567890'),
            ),
          );

      // Act - Insert without specifying isActive
      await database
          .into(database.contracts)
          .insert(
            ContractsCompanion(
              propertyId: Value(propertyId),
              tenantId: Value(tenantId),
              startDate: Value(DateTime.now()),
              endDate: Value(DateTime.now().add(const Duration(days: 365))),
              rentAmount: const Value(1000.0),
              paymentCycle: const Value('monthly'),
              depositAmount: const Value(2000.0),
              // Note: NOT setting isActive - should default to true
            ),
          );

      final contract = await database.select(database.contracts).getSingle();

      // Assert
      expect(contract.isActive, isTrue);
    });

    test('should set default value for Payment.isPartial to false', () async {
      // Arrange
      final propertyId = await database
          .into(database.properties)
          .insert(
            PropertiesCompanion(
              name: const Value('Test Property'),
              address: const Value('123 Test St'),
              propertyType: const Value('residential'),
            ),
          );

      final tenantId = await database
          .into(database.tenants)
          .insert(
            TenantsCompanion(
              name: const Value('Test Tenant'),
              phone: const Value('1234567890'),
            ),
          );

      final contractId = await database
          .into(database.contracts)
          .insert(
            ContractsCompanion(
              propertyId: Value(propertyId),
              tenantId: Value(tenantId),
              startDate: Value(DateTime.now()),
              endDate: Value(DateTime.now().add(const Duration(days: 365))),
              rentAmount: const Value(1000.0),
              paymentCycle: const Value('monthly'),
              depositAmount: const Value(2000.0),
            ),
          );

      // Act - Insert payment without specifying isPartial
      await database
          .into(database.payments)
          .insert(
            PaymentsCompanion(
              contractId: Value(contractId),
              amount: const Value(1000.0),
              paidDate: Value(DateTime.now()),
              dueDate: Value(DateTime.now()),
              paymentType: const Value('rent'),
              paymentMethod: const Value('bankTransfer'),
              // Note: NOT setting isPartial - should default to false
            ),
          );

      final payment = await database.select(database.payments).getSingle();

      // Assert
      expect(payment.isPartial, isFalse);
    });

    test(
      'should set default value for PaymentSchedule.isPaid to false',
      () async {
        // Arrange
        final propertyId = await database
            .into(database.properties)
            .insert(
              PropertiesCompanion(
                name: const Value('Test Property'),
                address: const Value('123 Test St'),
                propertyType: const Value('residential'),
              ),
            );

        final tenantId = await database
            .into(database.tenants)
            .insert(
              TenantsCompanion(
                name: const Value('Test Tenant'),
                phone: const Value('1234567890'),
              ),
            );

        final contractId = await database
            .into(database.contracts)
            .insert(
              ContractsCompanion(
                propertyId: Value(propertyId),
                tenantId: Value(tenantId),
                startDate: Value(DateTime.now()),
                endDate: Value(DateTime.now().add(const Duration(days: 365))),
                rentAmount: const Value(1000.0),
                paymentCycle: const Value('monthly'),
                depositAmount: const Value(2000.0),
              ),
            );

        // Act - Insert payment schedule without specifying isPaid
        await database
            .into(database.paymentSchedules)
            .insert(
              PaymentSchedulesCompanion(
                contractId: Value(contractId),
                dueDate: Value(DateTime.now().add(const Duration(days: 30))),
                amount: const Value(1000.0),
                // Note: NOT setting isPaid - should default to false
              ),
            );

        final schedule = await database
            .select(database.paymentSchedules)
            .getSingle();

        // Assert
        expect(schedule.isPaid, isFalse);
      },
    );
  });
}
