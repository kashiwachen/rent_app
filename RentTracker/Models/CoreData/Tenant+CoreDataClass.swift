import Foundation
import CoreData

@objc(Tenant)
public class Tenant: NSManagedObject {
    
    var activeContracts: [Contract] {
        guard let contracts = contracts?.allObjects as? [Contract] else { return [] }
        return contracts.filter { $0.isActive }
    }
    
    var currentProperties: [Property] {
        return activeContracts.compactMap { $0.property }
    }
    
    var totalRentOwed: Decimal {
        return activeContracts.reduce(0) { $0 + $1.overdueAmount }
    }
    
    var hasOverduePayments: Bool {
        return totalRentOwed > 0
    }
}

// MARK: - Convenience Initializer
extension Tenant {
    convenience init(context: NSManagedObjectContext, name: String, phone: String, email: String? = nil) {
        self.init(context: context)
        self.id = UUID()
        self.name = name
        self.phone = phone
        self.email = email
        self.createdAt = Date()
    }
}
