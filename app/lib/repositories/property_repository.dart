/// Repository for Property entity CRUD operations and business logic
///
/// Follows the Repository Pattern to abstract database operations
/// and provide a clean API for property management.
library;

import 'package:drift/drift.dart';

import '../core/database/app_database.dart';
import '../core/enums/enums.dart';
import '../models/property_with_contracts.dart';

/// Repository for managing property data and operations
class PropertyRepository {
  final AppDatabase _db;

  PropertyRepository(this._db);

  // ==========================================================================
  // CRUD OPERATIONS
  // ==========================================================================

  /// Creates a new property in the database
  ///
  /// [name] - Property name/identifier
  /// [address] - Physical address of the property
  /// [type] - Type of property (residential or commercial)
  ///
  /// Returns the created Property with generated ID
  ///
  /// Throws [Exception] if creation fails
  Future<Property> addProperty({
    required String name,
    required String address,
    required PropertyType type,
  }) async {
    try {
      final id = await _db
          .into(_db.properties)
          .insert(
            PropertiesCompanion.insert(
              name: name,
              address: address,
              propertyType: type.value,
            ),
          );

      final property = await (_db.select(
        _db.properties,
      )..where((t) => t.id.equals(id))).getSingle();

      return property;
    } catch (e) {
      throw Exception('Failed to add property: $e');
    }
  }

  /// Retrieves all properties from the database
  ///
  /// Returns empty list if no properties exist
  Future<List<Property>> getAllProperties() async {
    try {
      return await _db.select(_db.properties).get();
    } catch (e) {
      throw Exception('Failed to get all properties: $e');
    }
  }

  /// Retrieves a property by its ID
  ///
  /// Returns the Property if found, null otherwise
  Future<Property?> getPropertyById(int id) async {
    try {
      return await (_db.select(
        _db.properties,
      )..where((t) => t.id.equals(id))).getSingleOrNull();
    } catch (e) {
      throw Exception('Failed to get property by id: $e');
    }
  }

  /// Updates an existing property
  ///
  /// [property] - Property entity with updated values
  ///
  /// Throws [Exception] if property doesn't exist or update fails
  Future<void> updateProperty(Property property) async {
    try {
      final updated =
          await (_db.update(
            _db.properties,
          )..where((t) => t.id.equals(property.id))).write(
            PropertiesCompanion(
              name: Value(property.name),
              address: Value(property.address),
              propertyType: Value(property.propertyType),
              updatedAt: Value(DateTime.now()),
            ),
          );

      if (updated == 0) {
        throw Exception('Property with id ${property.id} not found');
      }
    } catch (e) {
      throw Exception('Failed to update property: $e');
    }
  }

  /// Deletes a property by its ID
  ///
  /// Cascades to delete all associated contracts, payments, and schedules
  /// Does not throw if property doesn't exist
  Future<void> deleteProperty(int id) async {
    try {
      await (_db.delete(_db.properties)..where((t) => t.id.equals(id))).go();
    } catch (e) {
      throw Exception('Failed to delete property: $e');
    }
  }

  // ==========================================================================
  // BUSINESS LOGIC
  // ==========================================================================

  /// Retrieves all properties with their associated contracts
  ///
  /// Returns a list of [PropertyWithContracts] objects where each property
  /// includes all its contracts (both active and inactive).
  ///
  /// Properties without contracts will have an empty contracts list.
  Future<List<PropertyWithContracts>> getPropertiesWithContracts() async {
    try {
      // Get all properties
      final properties = await _db.select(_db.properties).get();

      // For each property, get its contracts
      final result = <PropertyWithContracts>[];

      for (final property in properties) {
        final contracts = await (_db.select(
          _db.contracts,
        )..where((t) => t.propertyId.equals(property.id))).get();

        result.add(
          PropertyWithContracts(property: property, contracts: contracts),
        );
      }

      return result;
    } catch (e) {
      throw Exception('Failed to get properties with contracts: $e');
    }
  }

  /// Calculates the vacancy rate across all properties
  ///
  /// Vacancy rate = (number of vacant properties / total properties)
  /// A property is considered vacant if it has no active contracts
  ///
  /// Returns:
  /// - 0.0 if all properties are occupied
  /// - 1.0 if all properties are vacant
  /// - 0.0 if no properties exist
  Future<double> calculateVacancyRate() async {
    try {
      // Get total number of properties
      final totalProperties = await _db.select(_db.properties).get();
      if (totalProperties.isEmpty) {
        return 0.0;
      }

      // Get number of properties with active contracts
      final occupiedQuery = _db.selectOnly(_db.properties)
        ..addColumns([_db.properties.id])
        ..join([
          innerJoin(
            _db.contracts,
            _db.contracts.propertyId.equalsExp(_db.properties.id) &
                _db.contracts.isActive.equals(true),
          ),
        ])
        ..groupBy([_db.properties.id]);

      final occupiedResults = await occupiedQuery.get();
      final occupiedCount = occupiedResults.length;

      // Calculate vacancy rate
      final vacantCount = totalProperties.length - occupiedCount;
      return vacantCount / totalProperties.length;
    } catch (e) {
      throw Exception('Failed to calculate vacancy rate: $e');
    }
  }
}
