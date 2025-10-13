/// Core enumerations for the RentTracker app
///
/// These enums define the valid values for various domain concepts
/// and must match the database schema constraints.
library;

// ==============================================================================
// PROPERTY TYPE
// ==============================================================================

/// Type of rental property
enum PropertyType {
  /// Residential property (apartments, houses, etc.)
  residential('residential'),

  /// Commercial property (offices, retail spaces, etc.)
  commercial('commercial');

  /// String value for database storage
  final String value;

  const PropertyType(this.value);

  /// Convert string to PropertyType enum
  ///
  /// Throws [ArgumentError] if the string doesn't match any enum value
  static PropertyType fromString(String value) {
    return PropertyType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => throw ArgumentError(
        'Invalid PropertyType: $value. Valid values are: ${PropertyType.values.map((e) => e.value).join(", ")}',
      ),
    );
  }
}

// ==============================================================================
// PAYMENT CYCLE
// ==============================================================================

/// Frequency of rent payments
enum PaymentCycle {
  /// Monthly payments (every 1 month)
  monthly('monthly', 1),

  /// Bimonthly payments (every 2 months)
  bimonthly('bimonthly', 2),

  /// Quarterly payments (every 3 months)
  quarterly('quarterly', 3),

  /// Yearly payments (every 12 months)
  yearly('yearly', 12);

  /// String value for database storage
  final String value;

  /// Number of months between payments (used for schedule generation)
  final int months;

  const PaymentCycle(this.value, this.months);

  /// Convert string to PaymentCycle enum
  ///
  /// Throws [ArgumentError] if the string doesn't match any enum value
  static PaymentCycle fromString(String value) {
    return PaymentCycle.values.firstWhere(
      (cycle) => cycle.value == value,
      orElse: () => throw ArgumentError(
        'Invalid PaymentCycle: $value. Valid values are: ${PaymentCycle.values.map((e) => e.value).join(", ")}',
      ),
    );
  }
}

// ==============================================================================
// PAYMENT TYPE
// ==============================================================================

/// Type of payment transaction
enum PaymentType {
  /// Regular rent payment
  rent('rent'),

  /// Late fee payment (penalty for overdue rent)
  lateFee('lateFee'),

  /// Security deposit payment (paid at contract start)
  deposit('deposit'),

  /// Security deposit return (refunded at contract end)
  depositReturn('depositReturn');

  /// String value for database storage
  final String value;

  const PaymentType(this.value);

  /// Convert string to PaymentType enum
  ///
  /// Throws [ArgumentError] if the string doesn't match any enum value
  static PaymentType fromString(String value) {
    return PaymentType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => throw ArgumentError(
        'Invalid PaymentType: $value. Valid values are: ${PaymentType.values.map((e) => e.value).join(", ")}',
      ),
    );
  }
}

// ==============================================================================
// PAYMENT METHOD
// ==============================================================================

/// Method used for payment
enum PaymentMethod {
  /// Bank transfer (wire transfer, ACH, etc.)
  bankTransfer('bankTransfer'),

  /// WeChat Pay (popular in China)
  wechatPay('wechatPay'),

  /// Cash payment
  cash('cash');

  /// String value for database storage
  final String value;

  const PaymentMethod(this.value);

  /// Convert string to PaymentMethod enum
  ///
  /// Throws [ArgumentError] if the string doesn't match any enum value
  static PaymentMethod fromString(String value) {
    return PaymentMethod.values.firstWhere(
      (method) => method.value == value,
      orElse: () => throw ArgumentError(
        'Invalid PaymentMethod: $value. Valid values are: ${PaymentMethod.values.map((e) => e.value).join(", ")}',
      ),
    );
  }
}

// ==============================================================================
// EXPENSE CATEGORY
// ==============================================================================

/// Category of property expense
enum ExpenseCategory {
  /// Regular maintenance (cleaning, landscaping, etc.)
  maintenance('maintenance'),

  /// Repairs (fixing broken items)
  repair('repair'),

  /// Other miscellaneous expenses
  other('other');

  /// String value for database storage
  final String value;

  const ExpenseCategory(this.value);

  /// Convert string to ExpenseCategory enum
  ///
  /// Throws [ArgumentError] if the string doesn't match any enum value
  static ExpenseCategory fromString(String value) {
    return ExpenseCategory.values.firstWhere(
      (category) => category.value == value,
      orElse: () => throw ArgumentError(
        'Invalid ExpenseCategory: $value. Valid values are: ${ExpenseCategory.values.map((e) => e.value).join(", ")}',
      ),
    );
  }
}
