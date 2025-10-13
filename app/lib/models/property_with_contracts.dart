/// Model for property with its associated contracts
///
/// Used by PropertyRepository.getPropertiesWithContracts() to return
/// a property along with all its contracts (both active and inactive)
library;

import '../core/database/app_database.dart';

/// Represents a property with all its contracts
class PropertyWithContracts {
  /// The property entity
  final Property property;

  /// List of contracts associated with this property
  final List<Contract> contracts;

  const PropertyWithContracts({
    required this.property,
    required this.contracts,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PropertyWithContracts &&
          runtimeType == other.runtimeType &&
          property.id == other.property.id;

  @override
  int get hashCode => property.id.hashCode;

  @override
  String toString() {
    return 'PropertyWithContracts{property: ${property.name}, contractCount: ${contracts.length}}';
  }
}
