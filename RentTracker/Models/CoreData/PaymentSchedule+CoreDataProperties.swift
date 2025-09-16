import Foundation
import CoreData

extension PaymentSchedule {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PaymentSchedule> {
        return NSFetchRequest<PaymentSchedule>(entityName: "PaymentSchedule")
    }

    @NSManaged public var amount: NSDecimalNumber!
    @NSManaged public var dueDate: Date!
    @NSManaged public var id: UUID?
    @NSManaged public var isPaid: Bool
    @NSManaged public var paidDate: Date?
    @NSManaged public var contract: Contract?

}

extension PaymentSchedule : Identifiable {

}

// MARK: - Decimal Conversion
extension PaymentSchedule {
    var amount: Decimal {
        get { amount?.decimalValue ?? 0 }
        set { amount = NSDecimalNumber(decimal: newValue) }
    }
}
