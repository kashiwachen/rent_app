/// Model class that combines a Property with its associated Contracts
///
/// This model is used for business logic that needs to work with
/// properties and their rental history together.
library;

import '../core/database/app_database.dart';

/// A property with all its associated contracts
class PropertyWithContracts {
  /// The property entity
  final Property property;

  /// List of contracts associated with this property
  /// Empty list if property has no contracts
  final List<Contract> contracts;

  PropertyWithContracts({required this.property, required this.contracts});

  /// Returns the currently active contract for this property, if any
  Contract? get activeContract {
    try {
      return contracts.firstWhere((c) => c.isActive);
    } catch (_) {
      return null;
    }
  }

  /// Whether this property currently has an active contract
  bool get isOccupied => activeContract != null;

  /// Whether this property is currently vacant
  bool get isVacant => !isOccupied;

  /// Total number of contracts this property has had
  int get totalContracts => contracts.length;

  /// Number of active contracts for this property
  int get activeContractCount => contracts.where((c) => c.isActive).length;

  /// Number of inactive/expired contracts for this property
  int get inactiveContractCount => contracts.where((c) => !c.isActive).length;
}
