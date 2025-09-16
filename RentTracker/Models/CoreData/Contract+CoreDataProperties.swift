import Foundation
import CoreData

extension Contract {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Contract> {
        return NSFetchRequest<Contract>(entityName: "Contract")
    }

    @NSManaged public var createdAt: Date?
    @NSManaged public var depositAmount: NSDecimalNumber?
    @NSManaged public var endDate: Date!
    @NSManaged public var id: UUID?
    @NSManaged public var isActive: Bool
    @NSManaged public var paymentCycleRaw: String?
    @NSManaged public var rentAmount: NSDecimalNumber!
    @NSManaged public var startDate: Date!
    @NSManaged public var paymentSchedules: NSSet?
    @NSManaged public var payments: NSSet?
    @NSManaged public var property: Property?
    @NSManaged public var tenant: Tenant?

}

// MARK: Generated accessors for paymentSchedules
extension Contract {

    @objc(addPaymentSchedulesObject:)
    @NSManaged public func addToPaymentSchedules(_ value: PaymentSchedule)

    @objc(removePaymentSchedulesObject:)
    @NSManaged public func removeFromPaymentSchedules(_ value: PaymentSchedule)

    @objc(addPaymentSchedules:)
    @NSManaged public func addToPaymentSchedules(_ values: NSSet)

    @objc(removePaymentSchedules:)
    @NSManaged public func removeFromPaymentSchedules(_ values: NSSet)

}

// MARK: Generated accessors for payments
extension Contract {

    @objc(addPaymentsObject:)
    @NSManaged public func addToPayments(_ value: Payment)

    @objc(removePaymentsObject:)
    @NSManaged public func removeFromPayments(_ value: Payment)

    @objc(addPayments:)
    @NSManaged public func addToPayments(_ values: NSSet)

    @objc(removePayments:)
    @NSManaged public func removeFromPayments(_ values: NSSet)

}

extension Contract : Identifiable {

}

// MARK: - Decimal Conversion
extension Contract {
    var rentAmount: Decimal {
        get { rentAmount?.decimalValue ?? 0 }
        set { rentAmount = NSDecimalNumber(decimal: newValue) }
    }
    
    var depositAmount: Decimal {
        get { depositAmount?.decimalValue ?? 0 }
        set { depositAmount = NSDecimalNumber(decimal: newValue) }
    }
}
