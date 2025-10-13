/// Repository for property-related database operations
///
/// Provides CRUD operations and business logic for rental properties
library;

import 'package:drift/drift.dart';

import '../core/database/app_database.dart';
import '../core/enums/enums.dart';
import '../models/property_with_contracts.dart';

/// Repository for managing rental properties
class PropertyRepository {
  final AppDatabase _db;

  PropertyRepository(this._db);

  // ==========================================================================
  // CRUD OPERATIONS
  // ==========================================================================

  /// Creates a new property
  ///
  /// Returns the created [Property] with generated ID
  /// Throws exception if unique constraint is violated (duplicate name+address)
  Future<Property> addProperty({
    required String name,
    required String address,
    required PropertyType type,
  }) async {
    try {
      final id = await _db.into(_db.properties).insert(
            PropertiesCompanion.insert(
              name: name,
              address: address,
              propertyType: type.value,
            ),
          );

      final property = await (_db.select(_db.properties)
            ..where((t) => t.id.equals(id)))
          .getSingle();

      return property;
    } catch (e) {
      throw Exception('Failed to add property: $e');
    }
  }

  /// Retrieves all properties
  ///
  /// Returns empty list if no properties exist
  Future<List<Property>> getAllProperties() async {
    try {
      return await _db.select(_db.properties).get();
    } catch (e) {
      throw Exception('Failed to get all properties: $e');
    }
  }

  /// Retrieves a property by ID
  ///
  /// Returns null if property does not exist
  Future<Property?> getPropertyById(int id) async {
    try {
      final query = _db.select(_db.properties)..where((t) => t.id.equals(id));
      final results = await query.get();
      return results.isEmpty ? null : results.first;
    } catch (e) {
      throw Exception('Failed to get property by id: $e');
    }
  }

  /// Updates an existing property
  ///
  /// Updates the updatedAt timestamp automatically
  /// Throws exception if property does not exist
  Future<void> updateProperty(Property property) async {
    try {
      final updatedProperty = property.copyWith(
        updatedAt: DateTime.now(),
      );

      final rowsAffected = await (_db.update(_db.properties)
            ..where((t) => t.id.equals(property.id)))
          .write(
        PropertiesCompanion(
          name: Value(updatedProperty.name),
          address: Value(updatedProperty.address),
          propertyType: Value(updatedProperty.propertyType),
          updatedAt: Value(updatedProperty.updatedAt),
        ),
      );

      if (rowsAffected == 0) {
        throw Exception('Property with id ${property.id} not found');
      }
    } catch (e) {
      throw Exception('Failed to update property: $e');
    }
  }

  /// Deletes a property by ID
  ///
  /// Cascades to delete related contracts, payments, schedules, and expenses
  /// Does not throw if property does not exist
  Future<void> deleteProperty(int id) async {
    try {
      await (_db.delete(_db.properties)..where((t) => t.id.equals(id))).go();
    } catch (e) {
      throw Exception('Failed to delete property: $e');
    }
  }

  // ==========================================================================
  // BUSINESS LOGIC METHODS
  // ==========================================================================

  /// Retrieves all properties with their associated contracts
  ///
  /// Returns a list of [PropertyWithContracts] objects, where each object
  /// contains a property and all its contracts (both active and inactive)
  Future<List<PropertyWithContracts>> getPropertiesWithContracts() async {
    try {
      // Get all properties
      final properties = await getAllProperties();

      // For each property, fetch its contracts
      final results = <PropertyWithContracts>[];
      for (final property in properties) {
        final contracts = await (_db.select(_db.contracts)
              ..where((t) => t.propertyId.equals(property.id)))
            .get();

        results.add(PropertyWithContracts(
          property: property,
          contracts: contracts,
        ));
      }

      return results;
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
