import Foundation
import CoreData

@objc(Property)
public class Property: NSManagedObject {
    
    var propertyType: PropertyType {
        get {
            return PropertyType(rawValue: propertyTypeRaw ?? PropertyType.residential.rawValue) ?? .residential
        }
        set {
            propertyTypeRaw = newValue.rawValue
        }
    }
    
    var activeContract: Contract? {
        return contracts?.first(where: { $0.isActive })
    }
    
    var currentTenant: Tenant? {
        return activeContract?.tenant
    }
    
    var totalIncome: Decimal {
        let payments = contracts?.compactMap { $0.payments?.allObjects as? [Payment] }.flatMap { $0 } ?? []
        return payments.filter { $0.paymentType.isIncome }.reduce(0) { $0 + $1.amount }
    }
    
    var totalExpenses: Decimal {
        return expenses?.reduce(0) { $0 + $1.amount } ?? 0
    }
    
    var netIncome: Decimal {
        return totalIncome - totalExpenses
    }
    
    var isVacant: Bool {
        return activeContract == nil
    }
    
    var overduePayments: [PaymentSchedule] {
        guard let activeContract = activeContract,
              let schedules = activeContract.paymentSchedules?.allObjects as? [PaymentSchedule] else {
            return []
        }
        
        let today = Date()
        return schedules.filter { !$0.isPaid && $0.dueDate < today }
    }
}

// MARK: - Convenience Initializer
extension Property {
    convenience init(context: NSManagedObjectContext, name: String, address: String, type: PropertyType) {
        self.init(context: context)
        self.id = UUID()
        self.name = name
        self.address = address
        self.propertyType = type
        self.createdAt = Date()
    }
}
