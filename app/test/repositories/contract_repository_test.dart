/// Unit tests for ContractRepository
///
/// Tests all methods including complex payment schedule generation following TDD principles
library;

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import '../../lib/core/database/app_database.dart';
import '../../lib/core/enums/enums.dart';
import '../../lib/repositories/contract_repository.dart';
import '../helpers/database_helper.dart';

void main() {
  late AppDatabase db;
  late ContractRepository repository;

  setUp(() {
    db = createTestDatabase();
    repository = ContractRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('ContractRepository - CRUD Operations', () {
    test('createContract - should create contract with monthly cycle', () async {
      // Arrange
      final propertyIds = await seedTestProperties(db);
      final tenantIds = await seedTestTenants(db);
      final startDate = DateTime(2025, 1, 1);
      final endDate = DateTime(2025, 12, 31);

      // Act
      final contract = await repository.createContract(
        propertyId: propertyIds[0],
        tenantId: tenantIds[0],
        startDate: startDate,
        endDate: endDate,
        rentAmount: 1000.0,
        cycle: PaymentCycle.monthly,
        depositAmount: 2000.0,
      );

      // Assert
      expect(contract.id, greaterThan(0));
      expect(contract.propertyId, propertyIds[0]);
      expect(contract.tenantId, tenantIds[0]);
      expect(contract.startDate, startDate);
      expect(contract.endDate, endDate);
      expect(contract.rentAmount, 1000.0);
      expect(contract.paymentCycle, PaymentCycle.monthly.value);
      expect(contract.depositAmount, 2000.0);
      expect(contract.isActive, isTrue);
    });

    test('createContract - should throw when property does not exist', () async {
      // Arrange
      final tenantIds = await seedTestTenants(db);

      // Act & Assert
      expect(
        () => repository.createContract(
          propertyId: 999,
          tenantId: tenantIds[0],
          startDate: DateTime.now(),
          endDate: DateTime.now().add(const Duration(days: 365)),
          rentAmount: 1000.0,
          cycle: PaymentCycle.monthly,
          depositAmount: 2000.0,
        ),
        throwsException,
      );
    });

    test('createContract - should throw when tenant does not exist', () async {
      // Arrange
      final propertyIds = await seedTestProperties(db);

      // Act & Assert
      expect(
        () => repository.createContract(
          propertyId: propertyIds[0],
          tenantId: 999,
          startDate: DateTime.now(),
          endDate: DateTime.now().add(const Duration(days: 365)),
          rentAmount: 1000.0,
          cycle: PaymentCycle.monthly,
          depositAmount: 2000.0,
        ),
        throwsException,
      );
    });

    test('getAllContracts - should return empty list when no contracts exist',
        () async {
      // Act
      final contracts = await repository.getAllContracts();

      // Assert
      expect(contracts, isEmpty);
    });

    test('getAllContracts - should return all contracts', () async {
      // Arrange
      final propertyIds = await seedTestProperties(db);
      final tenantIds = await seedTestTenants(db);
      await seedTestContracts(db, propertyIds, tenantIds);

      // Act
      final contracts = await repository.getAllContracts();

      // Assert
      expect(contracts, hasLength(3));
    });

    test('getActiveContracts - should return only active contracts', () async {
      // Arrange
      final propertyIds = await seedTestProperties(db);
      final tenantIds = await seedTestTenants(db);
      await seedTestContracts(db, propertyIds, tenantIds);

      // Act
      final activeContracts = await repository.getActiveContracts();

      // Assert
      expect(activeContracts.length, 2); // Only 2 active from seed data
      expect(activeContracts.every((c) => c.isActive), isTrue);
    });

    test('getActiveContracts - should return empty list when no active contracts',
        () async {
      // Arrange
      final propertyIds = await seedTestProperties(db);
      final tenantIds = await seedTestTenants(db);
      final contractIds = await seedTestContracts(db, propertyIds, tenantIds);

      // Make all contracts inactive
      for (final id in contractIds) {
        await (db.update(db.contracts)..where((t) => t.id.equals(id)))
            .write(const ContractsCompanion(isActive: Value(false)));
      }

      // Act
      final activeContracts = await repository.getActiveContracts();

      // Assert
      expect(activeContracts, isEmpty);
    });

    test('getContractById - should return contract when id exists', () async {
      // Arrange
      final propertyIds = await seedTestProperties(db);
      final tenantIds = await seedTestTenants(db);
      final contractIds = await seedTestContracts(db, propertyIds, tenantIds);

      // Act
      final contract = await repository.getContractById(contractIds[0]);

      // Assert
      expect(contract, isNotNull);
      expect(contract!.id, contractIds[0]);
    });

    test('getContractById - should return null when id does not exist',
        () async {
      // Act
      final contract = await repository.getContractById(999);

      // Assert
      expect(contract, isNull);
    });

    test('updateContract - should update existing contract', () async {
      // Arrange
      final propertyIds = await seedTestProperties(db);
      final tenantIds = await seedTestTenants(db);
      final contractIds = await seedTestContracts(db, propertyIds, tenantIds);
      final contract = await repository.getContractById(contractIds[0]);

      final updated = contract!.copyWith(
        rentAmount: 1500.0,
        depositAmount: 3000.0,
      );

      // Act
      await repository.updateContract(updated);
      final result = await repository.getContractById(contractIds[0]);

      // Assert
      expect(result, isNotNull);
      expect(result!.rentAmount, 1500.0);
      expect(result.depositAmount, 3000.0);
    });

    test('updateContract - should throw when contract does not exist', () async {
      // Arrange
      final nonExistent = Contract(
        id: 999,
        propertyId: 1,
        tenantId: 1,
        startDate: DateTime.now(),
        endDate: DateTime.now(),
        rentAmount: 1000.0,
        paymentCycle: PaymentCycle.monthly.value,
        depositAmount: 2000.0,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act & Assert
      expect(() => repository.updateContract(nonExistent), throwsException);
    });

    test('terminateContract - should mark contract as inactive', () async {
      // Arrange
      final propertyIds = await seedTestProperties(db);
      final tenantIds = await seedTestTenants(db);
      final contractIds = await seedTestContracts(db, propertyIds, tenantIds);

      // Verify contract is active
      final before = await repository.getContractById(contractIds[0]);
      expect(before!.isActive, isTrue);

      // Act
      await repository.terminateContract(contractIds[0]);

      // Assert
      final after = await repository.getContractById(contractIds[0]);
      expect(after!.isActive, isFalse);
    });

    test('terminateContract - should throw when contract does not exist',
        () async {
      // Act & Assert
      expect(() => repository.terminateContract(999), throwsException);
    });
  });

  group('ContractRepository - Payment Schedule Generation', () {
    test(
        'generatePaymentSchedules - should generate 12 monthly schedules for 1 year',
        () async {
      // Arrange
      final propertyIds = await seedTestProperties(db);
      final tenantIds = await seedTestTenants(db);
      final contract = await repository.createContract(
        propertyId: propertyIds[0],
        tenantId: tenantIds[0],
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 12, 31),
        rentAmount: 1000.0,
        cycle: PaymentCycle.monthly,
        depositAmount: 2000.0,
      );

      // Act
      final schedules = await repository.generatePaymentSchedules(
        contract.id,
        contract.startDate,
        contract.endDate,
        PaymentCycle.monthly,
        contract.rentAmount,
      );

      // Assert
      expect(schedules, hasLength(12));
      expect(schedules[0].dueDate, DateTime(2025, 1, 1));
      expect(schedules[1].dueDate, DateTime(2025, 2, 1));
      expect(schedules[11].dueDate, DateTime(2025, 12, 1));
      expect(schedules.every((s) => s.amount == 1000.0), isTrue);
      expect(schedules.every((s) => s.isPaid == false), isTrue);
    });

    test(
        'generatePaymentSchedules - should generate 4 quarterly schedules for 1 year',
        () async {
      // Arrange
      final propertyIds = await seedTestProperties(db);
      final tenantIds = await seedTestTenants(db);
      final contract = await repository.createContract(
        propertyId: propertyIds[0],
        tenantId: tenantIds[0],
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 12, 31),
        rentAmount: 3000.0,
        cycle: PaymentCycle.quarterly,
        depositAmount: 6000.0,
      );

      // Act
      final schedules = await repository.generatePaymentSchedules(
        contract.id,
        contract.startDate,
        contract.endDate,
        PaymentCycle.quarterly,
        contract.rentAmount,
      );

      // Assert
      expect(schedules, hasLength(4));
      expect(schedules[0].dueDate, DateTime(2025, 1, 1));
      expect(schedules[1].dueDate, DateTime(2025, 4, 1));
      expect(schedules[2].dueDate, DateTime(2025, 7, 1));
      expect(schedules[3].dueDate, DateTime(2025, 10, 1));
      expect(schedules.every((s) => s.amount == 3000.0), isTrue);
    });

    test(
        'generatePaymentSchedules - should generate 6 bimonthly schedules for 1 year',
        () async {
      // Arrange
      final propertyIds = await seedTestProperties(db);
      final tenantIds = await seedTestTenants(db);
      final contract = await repository.createContract(
        propertyId: propertyIds[0],
        tenantId: tenantIds[0],
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 12, 31),
        rentAmount: 2000.0,
        cycle: PaymentCycle.bimonthly,
        depositAmount: 4000.0,
      );

      // Act
      final schedules = await repository.generatePaymentSchedules(
        contract.id,
        contract.startDate,
        contract.endDate,
        PaymentCycle.bimonthly,
        contract.rentAmount,
      );

      // Assert
      expect(schedules, hasLength(6));
      expect(schedules[0].dueDate, DateTime(2025, 1, 1));
      expect(schedules[1].dueDate, DateTime(2025, 3, 1));
      expect(schedules[2].dueDate, DateTime(2025, 5, 1));
      expect(schedules[5].dueDate, DateTime(2025, 11, 1));
    });

    test('generatePaymentSchedules - should generate 1 yearly schedule',
        () async {
      // Arrange
      final propertyIds = await seedTestProperties(db);
      final tenantIds = await seedTestTenants(db);
      final contract = await repository.createContract(
        propertyId: propertyIds[0],
        tenantId: tenantIds[0],
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 12, 31),
        rentAmount: 12000.0,
        cycle: PaymentCycle.yearly,
        depositAmount: 24000.0,
      );

      // Act
      final schedules = await repository.generatePaymentSchedules(
        contract.id,
        contract.startDate,
        contract.endDate,
        PaymentCycle.yearly,
        contract.rentAmount,
      );

      // Assert
      expect(schedules, hasLength(1));
      expect(schedules[0].dueDate, DateTime(2025, 1, 1));
      expect(schedules[0].amount, 12000.0);
    });

    test(
        'generatePaymentSchedules - should handle mid-month start date correctly',
        () async {
      // Arrange
      final propertyIds = await seedTestProperties(db);
      final tenantIds = await seedTestTenants(db);
      final contract = await repository.createContract(
        propertyId: propertyIds[0],
        tenantId: tenantIds[0],
        startDate: DateTime(2025, 1, 15),
        endDate: DateTime(2025, 7, 15),
        rentAmount: 1000.0,
        cycle: PaymentCycle.monthly,
        depositAmount: 2000.0,
      );

      // Act
      final schedules = await repository.generatePaymentSchedules(
        contract.id,
        contract.startDate,
        contract.endDate,
        PaymentCycle.monthly,
        contract.rentAmount,
      );

      // Assert
      expect(schedules, hasLength(7));
      expect(schedules[0].dueDate, DateTime(2025, 1, 15));
      expect(schedules[1].dueDate, DateTime(2025, 2, 15));
      expect(schedules[6].dueDate, DateTime(2025, 7, 15));
    });

    test('generatePaymentSchedules - should handle multi-year contracts',
        () async {
      // Arrange
      final propertyIds = await seedTestProperties(db);
      final tenantIds = await seedTestTenants(db);
      final contract = await repository.createContract(
        propertyId: propertyIds[0],
        tenantId: tenantIds[0],
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2027, 1, 1),
        rentAmount: 1000.0,
        cycle: PaymentCycle.monthly,
        depositAmount: 2000.0,
      );

      // Act
      final schedules = await repository.generatePaymentSchedules(
        contract.id,
        contract.startDate,
        contract.endDate,
        PaymentCycle.monthly,
        contract.rentAmount,
      );

      // Assert
      expect(schedules, hasLength(25)); // 2 years * 12 + 1 month
      expect(schedules[0].dueDate, DateTime(2025, 1, 1));
      expect(schedules[12].dueDate, DateTime(2026, 1, 1));
      expect(schedules[24].dueDate, DateTime(2027, 1, 1));
    });

    test('generatePaymentSchedules - should handle February edge case',
        () async {
      // Arrange
      final propertyIds = await seedTestProperties(db);
      final tenantIds = await seedTestTenants(db);
      final contract = await repository.createContract(
        propertyId: propertyIds[0],
        tenantId: tenantIds[0],
        startDate: DateTime(2025, 1, 31),
        endDate: DateTime(2025, 3, 31),
        rentAmount: 1000.0,
        cycle: PaymentCycle.monthly,
        depositAmount: 2000.0,
      );

      // Act
      final schedules = await repository.generatePaymentSchedules(
        contract.id,
        contract.startDate,
        contract.endDate,
        PaymentCycle.monthly,
        contract.rentAmount,
      );

      // Assert
      expect(schedules, hasLength(3));
      expect(schedules[0].dueDate, DateTime(2025, 1, 31));
      // February 31 doesn't exist, should adjust to Feb 28
      expect(schedules[1].dueDate, DateTime(2025, 2, 28));
      // March should also be 28 (stays at clamped day)
      expect(schedules[2].dueDate, DateTime(2025, 3, 28));
    });

    test('generatePaymentSchedules - should throw when contract does not exist',
        () async {
      // Act & Assert
      expect(
        () => repository.generatePaymentSchedules(
          999,
          DateTime.now(),
          DateTime.now().add(const Duration(days: 365)),
          PaymentCycle.monthly,
          1000.0,
        ),
        throwsException,
      );
    });
  });

  group('ContractRepository - Edge Cases', () {
    test('createContract - should handle zero deposit amount', () async {
      // Arrange
      final propertyIds = await seedTestProperties(db);
      final tenantIds = await seedTestTenants(db);

      // Act
      final contract = await repository.createContract(
        propertyId: propertyIds[0],
        tenantId: tenantIds[0],
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 12, 31),
        rentAmount: 1000.0,
        cycle: PaymentCycle.monthly,
        depositAmount: 0.0,
      );

      // Assert
      expect(contract.depositAmount, 0.0);
    });

    test('createContract - should handle short-term contract (1 month)',
        () async {
      // Arrange
      final propertyIds = await seedTestProperties(db);
      final tenantIds = await seedTestTenants(db);

      // Act
      final contract = await repository.createContract(
        propertyId: propertyIds[0],
        tenantId: tenantIds[0],
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 1, 31),
        rentAmount: 1000.0,
        cycle: PaymentCycle.monthly,
        depositAmount: 2000.0,
      );

      // Assert
      expect(contract.id, greaterThan(0));
      expect(contract.isActive, isTrue);
    });

    test('updateContract - should preserve createdAt timestamp', () async {
      // Arrange
      final propertyIds = await seedTestProperties(db);
      final tenantIds = await seedTestTenants(db);
      final contractIds = await seedTestContracts(db, propertyIds, tenantIds);
      final original = await repository.getContractById(contractIds[0]);

      await Future.delayed(const Duration(milliseconds: 100));

      // Act
      final updated = original!.copyWith(rentAmount: 1500.0);
      await repository.updateContract(updated);
      final result = await repository.getContractById(contractIds[0]);

      // Assert
      expect(result!.createdAt, original.createdAt);
      expect(
        result.updatedAt.isAfter(original.updatedAt) ||
            result.updatedAt.isAtSameMomentAs(original.updatedAt),
        isTrue,
      );
    });
  });
}
