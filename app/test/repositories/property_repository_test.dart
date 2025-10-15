/// Unit tests for PropertyRepository
///
/// Tests all CRUD operations and business logic methods following TDD principles
library;

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import '../../lib/core/database/app_database.dart';
import '../../lib/core/enums/enums.dart';
import '../../lib/repositories/property_repository.dart';
import '../helpers/database_helper.dart';

void main() {
  late AppDatabase db;
  late PropertyRepository repository;

  setUp(() {
    db = createTestDatabase();
    repository = PropertyRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('PropertyRepository - CRUD Operations', () {
    test('addProperty - should create a new residential property', () async {
      // Act
      final property = await repository.addProperty(
        name: 'Test Apartment',
        address: '123 Test St',
        type: PropertyType.residential,
      );

      // Assert
      expect(property.id, greaterThan(0));
      expect(property.name, 'Test Apartment');
      expect(property.address, '123 Test St');
      expect(property.propertyType, PropertyType.residential.value);
      expect(property.createdAt, isNotNull);
      expect(property.updatedAt, isNotNull);
    });

    test('addProperty - should create a new commercial property', () async {
      // Act
      final property = await repository.addProperty(
        name: 'Office Space',
        address: '456 Business Ave',
        type: PropertyType.commercial,
      );

      // Assert
      expect(property.id, greaterThan(0));
      expect(property.propertyType, PropertyType.commercial.value);
    });

    test(
      'addProperty - should enforce unique constraint on name+address',
      () async {
        // Arrange
        await repository.addProperty(
          name: 'Duplicate Property',
          address: '789 Same St',
          type: PropertyType.residential,
        );

        // Act & Assert
        expect(
          () => repository.addProperty(
            name: 'Duplicate Property',
            address: '789 Same St',
            type: PropertyType.commercial,
          ),
          throwsException,
        );
      },
    );

    test(
      'getAllProperties - should return empty list when no properties exist',
      () async {
        // Act
        final properties = await repository.getAllProperties();

        // Assert
        expect(properties, isEmpty);
      },
    );

    test('getAllProperties - should return all properties', () async {
      // Arrange
      await repository.addProperty(
        name: 'Property 1',
        address: 'Address 1',
        type: PropertyType.residential,
      );
      await repository.addProperty(
        name: 'Property 2',
        address: 'Address 2',
        type: PropertyType.commercial,
      );

      // Act
      final properties = await repository.getAllProperties();

      // Assert
      expect(properties, hasLength(2));
      expect(properties[0].name, 'Property 1');
      expect(properties[1].name, 'Property 2');
    });

    test('getPropertyById - should return property when id exists', () async {
      // Arrange
      final created = await repository.addProperty(
        name: 'Find Me',
        address: 'Findable Address',
        type: PropertyType.residential,
      );

      // Act
      final property = await repository.getPropertyById(created.id);

      // Assert
      expect(property, isNotNull);
      expect(property!.id, created.id);
      expect(property.name, 'Find Me');
      expect(property.address, 'Findable Address');
    });

    test(
      'getPropertyById - should return null when id does not exist',
      () async {
        // Act
        final property = await repository.getPropertyById(999);

        // Assert
        expect(property, isNull);
      },
    );

    test('updateProperty - should update existing property', () async {
      // Arrange
      final created = await repository.addProperty(
        name: 'Old Name',
        address: 'Old Address',
        type: PropertyType.residential,
      );

      // Wait to ensure updatedAt timestamp will be different
      await Future.delayed(const Duration(milliseconds: 100));

      final updated = created.copyWith(
        name: 'New Name',
        address: 'New Address',
        propertyType: PropertyType.commercial.value,
      );

      // Act
      await repository.updateProperty(updated);
      final result = await repository.getPropertyById(created.id);

      // Assert
      expect(result, isNotNull);
      expect(result!.name, 'New Name');
      expect(result.address, 'New Address');
      expect(result.propertyType, PropertyType.commercial.value);
      // updatedAt should be at least as recent as createdAt
      expect(
        result.updatedAt.isAfter(created.updatedAt) ||
            result.updatedAt.isAtSameMomentAs(created.updatedAt),
        isTrue,
      );
    });

    test(
      'updateProperty - should throw when property does not exist',
      () async {
        // Arrange
        final nonExistentProperty = Property(
          id: 999,
          name: 'Non Existent',
          address: 'Nowhere',
          propertyType: PropertyType.residential.value,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Act & Assert
        expect(
          () => repository.updateProperty(nonExistentProperty),
          throwsException,
        );
      },
    );

    test('deleteProperty - should delete existing property', () async {
      // Arrange
      final created = await repository.addProperty(
        name: 'Delete Me',
        address: 'Deletable Address',
        type: PropertyType.residential,
      );

      // Act
      await repository.deleteProperty(created.id);
      final result = await repository.getPropertyById(created.id);

      // Assert
      expect(result, isNull);
    });

    test(
      'deleteProperty - should not throw when property does not exist',
      () async {
        // Act & Assert
        expect(() => repository.deleteProperty(999), returnsNormally);
      },
    );

    test('deleteProperty - should cascade delete related contracts', () async {
      // Arrange
      final propertyIds = await seedTestProperties(db);
      final tenantIds = await seedTestTenants(db);
      await seedTestContracts(db, propertyIds, tenantIds);

      // Verify contract exists
      final contractsBefore = await (db.select(
        db.contracts,
      )..where((t) => t.propertyId.equals(propertyIds[0]))).get();
      expect(contractsBefore, isNotEmpty);

      // Act
      await repository.deleteProperty(propertyIds[0]);

      // Assert - contracts should be deleted due to cascade
      final contractsAfter = await (db.select(
        db.contracts,
      )..where((t) => t.propertyId.equals(propertyIds[0]))).get();
      expect(contractsAfter, isEmpty);
    });
  });

  group('PropertyRepository - Business Logic', () {
    test(
      'getPropertiesWithContracts - should return empty list when no data',
      () async {
        // Act
        final result = await repository.getPropertiesWithContracts();

        // Assert
        expect(result, isEmpty);
      },
    );

    test(
      'getPropertiesWithContracts - should return properties with contracts',
      () async {
        // Arrange
        final propertyIds = await seedTestProperties(db);
        final tenantIds = await seedTestTenants(db);
        await seedTestContracts(db, propertyIds, tenantIds);

        // Act
        final result = await repository.getPropertiesWithContracts();

        // Assert
        expect(result, hasLength(3)); // 3 properties seeded
        expect(result[0].property, isNotNull);
        expect(result[0].contracts, isNotEmpty);
        expect(result[0].contracts.length, greaterThan(0));
      },
    );

    test(
      'getPropertiesWithContracts - should include properties without contracts',
      () async {
        // Arrange
        await repository.addProperty(
          name: 'No Contract Property',
          address: 'No Contract Address',
          type: PropertyType.residential,
        );

        // Act
        final result = await repository.getPropertiesWithContracts();

        // Assert
        expect(result, hasLength(1));
        expect(result[0].contracts, isEmpty);
      },
    );

    test(
      'getPropertiesWithContracts - should group contracts by property correctly',
      () async {
        // Arrange
        final propertyIds = await seedTestProperties(db);
        final tenantIds = await seedTestTenants(db);
        await seedTestContracts(db, propertyIds, tenantIds);

        // Add another contract for the first property
        await db
            .into(db.contracts)
            .insert(
              ContractsCompanion.insert(
                propertyId: propertyIds[0],
                tenantId: tenantIds[1],
                startDate: DateTime.now().add(const Duration(days: 365)),
                endDate: DateTime.now().add(const Duration(days: 730)),
                rentAmount: 1200.0,
                paymentCycle: PaymentCycle.monthly.value,
                depositAmount: 2400.0,
                isActive: const Value(true),
              ),
            );

        // Act
        final result = await repository.getPropertiesWithContracts();

        // Assert
        final firstProperty = result.firstWhere(
          (pw) => pw.property.id == propertyIds[0],
        );
        expect(firstProperty.contracts, hasLength(2));
      },
    );

    test(
      'calculateVacancyRate - should return 0 when no properties exist',
      () async {
        // Act
        final rate = await repository.calculateVacancyRate();

        // Assert
        expect(rate, 0.0);
      },
    );

    test(
      'calculateVacancyRate - should return 1.0 when all properties vacant',
      () async {
        // Arrange
        await repository.addProperty(
          name: 'Vacant 1',
          address: 'Address 1',
          type: PropertyType.residential,
        );
        await repository.addProperty(
          name: 'Vacant 2',
          address: 'Address 2',
          type: PropertyType.commercial,
        );

        // Act
        final rate = await repository.calculateVacancyRate();

        // Assert
        expect(rate, 1.0);
      },
    );

    test(
      'calculateVacancyRate - should return 0.0 when all properties occupied',
      () async {
        // Arrange
        final propertyIds = await seedTestProperties(db);
        final tenantIds = await seedTestTenants(db);
        await seedTestContracts(db, propertyIds, tenantIds);

        // Make all contracts active
        await db
            .update(db.contracts)
            .write(const ContractsCompanion(isActive: Value(true)));

        // Act
        final rate = await repository.calculateVacancyRate();

        // Assert
        expect(rate, 0.0);
      },
    );

    test(
      'calculateVacancyRate - should calculate correct rate with mixed occupancy',
      () async {
        // Arrange
        final propertyIds = await seedTestProperties(db);
        final tenantIds = await seedTestTenants(db);
        await seedTestContracts(db, propertyIds, tenantIds);

        // We have 3 properties: 2 with active contracts, 1 with inactive
        // Expected vacancy rate = 1/3 ≈ 0.333...

        // Act
        final rate = await repository.calculateVacancyRate();

        // Assert
        expect(rate, closeTo(0.333, 0.01));
      },
    );

    test('calculateVacancyRate - should only count active contracts', () async {
      // Arrange
      final property = await repository.addProperty(
        name: 'Test Property',
        address: 'Test Address',
        type: PropertyType.residential,
      );
      final tenantIds = await seedTestTenants(db);

      // Add inactive contract
      await db
          .into(db.contracts)
          .insert(
            ContractsCompanion.insert(
              propertyId: property.id,
              tenantId: tenantIds[0],
              startDate: DateTime.now().subtract(const Duration(days: 100)),
              endDate: DateTime.now().subtract(const Duration(days: 1)),
              rentAmount: 1000.0,
              paymentCycle: PaymentCycle.monthly.value,
              depositAmount: 2000.0,
              isActive: const Value(false),
            ),
          );

      // Act
      final rate = await repository.calculateVacancyRate();

      // Assert
      expect(rate, 1.0); // Property should be considered vacant
    });
  });

  group('PropertyRepository - Edge Cases', () {
    test('addProperty - should handle special characters in name', () async {
      // Act
      final property = await repository.addProperty(
        name: "O'Malley's Apartment #42",
        address: '123 Test St',
        type: PropertyType.residential,
      );

      // Assert
      expect(property.name, "O'Malley's Apartment #42");
    });

    test('addProperty - should handle unicode characters in address', () async {
      // Act
      final property = await repository.addProperty(
        name: 'Test Property',
        address: '北京市朝阳区建国路 123号',
        type: PropertyType.residential,
      );

      // Assert
      expect(property.address, '北京市朝阳区建国路 123号');
    });

    test('getAllProperties - should maintain insertion order', () async {
      // Arrange
      final names = ['Alpha', 'Beta', 'Gamma', 'Delta'];
      for (final name in names) {
        await repository.addProperty(
          name: name,
          address: 'Address $name',
          type: PropertyType.residential,
        );
      }

      // Act
      final properties = await repository.getAllProperties();

      // Assert
      expect(properties.map((p) => p.name).toList(), names);
    });

    test('updateProperty - should preserve createdAt timestamp', () async {
      // Arrange
      final created = await repository.addProperty(
        name: 'Original',
        address: 'Original Address',
        type: PropertyType.residential,
      );

      // Wait to ensure updatedAt changes
      await Future.delayed(const Duration(milliseconds: 100));

      // Act
      final updated = created.copyWith(name: 'Updated');
      await repository.updateProperty(updated);
      final result = await repository.getPropertyById(created.id);

      // Assert
      expect(result!.createdAt, created.createdAt);
      // updatedAt should be at least as recent as initial updatedAt
      expect(
        result.updatedAt.isAfter(created.updatedAt) ||
            result.updatedAt.isAtSameMomentAs(created.updatedAt),
        isTrue,
      );
    });
  });
}
