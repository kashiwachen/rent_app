import Foundation

// MARK: - Property Type
enum PropertyType: String, CaseIterable, Identifiable {
    case residential = "residential"
    case commercial = "commercial"
    
    var id: String { self.rawValue }
    
    var localizedName: String {
        switch self {
        case .residential:
            return NSLocalizedString("Residential", comment: "Residential property type")
        case .commercial:
            return NSLocalizedString("Commercial", comment: "Commercial property type")
        }
    }
}

// MARK: - Payment Cycle
enum PaymentCycle: String, CaseIterable, Identifiable {
    case monthly = "monthly"
    case bimonthly = "bimonthly"
    case quarterly = "quarterly"
    case yearly = "yearly"
    
    var id: String { self.rawValue }
    
    var localizedName: String {
        switch self {
        case .monthly:
            return NSLocalizedString("Monthly", comment: "Monthly payment cycle")
        case .bimonthly:
            return NSLocalizedString("Bi-monthly", comment: "Bi-monthly payment cycle")
        case .quarterly:
            return NSLocalizedString("Quarterly", comment: "Quarterly payment cycle")
        case .yearly:
            return NSLocalizedString("Yearly", comment: "Yearly payment cycle")
        }
    }
    
    var monthsInterval: Int {
        switch self {
        case .monthly: return 1
        case .bimonthly: return 2
        case .quarterly: return 3
        case .yearly: return 12
        }
    }
}

// MARK: - Payment Type
enum PaymentType: String, CaseIterable, Identifiable {
    case rent = "rent"
    case lateFee = "lateFee"
    case deposit = "deposit"
    case depositReturn = "depositReturn"
    
    var id: String { self.rawValue }
    
    var localizedName: String {
        switch self {
        case .rent:
            return NSLocalizedString("Rent", comment: "Rent payment type")
        case .lateFee:
            return NSLocalizedString("Late Fee", comment: "Late fee payment type")
        case .deposit:
            return NSLocalizedString("Deposit", comment: "Deposit payment type")
        case .depositReturn:
            return NSLocalizedString("Deposit Return", comment: "Deposit return payment type")
        }
    }
    
    var isIncome: Bool {
        switch self {
        case .rent, .lateFee, .deposit:
            return true
        case .depositReturn:
            return false
        }
    }
}

// MARK: - Payment Method
enum PaymentMethod: String, CaseIterable, Identifiable {
    case bankTransfer = "bankTransfer"
    case wechatPay = "wechatPay"
    case cash = "cash"
    
    var id: String { self.rawValue }
    
    var localizedName: String {
        switch self {
        case .bankTransfer:
            return NSLocalizedString("Bank Transfer", comment: "Bank transfer payment method")
        case .wechatPay:
            return NSLocalizedString("WeChat Pay", comment: "WeChat Pay payment method")
        case .cash:
            return NSLocalizedString("Cash", comment: "Cash payment method")
        }
    }
    
    var iconName: String {
        switch self {
        case .bankTransfer: return "building.columns"
        case .wechatPay: return "message"
        case .cash: return "banknote"
        }
    }
}

// MARK: - Expense Category
enum ExpenseCategory: String, CaseIterable, Identifiable {
    case maintenance = "maintenance"
    case repair = "repair"
    case other = "other"
    
    var id: String { self.rawValue }
    
    var localizedName: String {
        switch self {
        case .maintenance:
            return NSLocalizedString("Maintenance", comment: "Maintenance expense category")
        case .repair:
            return NSLocalizedString("Repair", comment: "Repair expense category")
        case .other:
            return NSLocalizedString("Other", comment: "Other expense category")
        }
    }
    
    var iconName: String {
        switch self {
        case .maintenance: return "wrench"
        case .repair: return "hammer"
        case .other: return "ellipsis.circle"
        }
    }
}
