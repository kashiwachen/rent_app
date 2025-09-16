import Foundation
import CoreData

extension Payment {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Payment> {
        return NSFetchRequest<Payment>(entityName: "Payment")
    }

    @NSManaged public var amount: NSDecimalNumber!
    @NSManaged public var dueDate: Date!
    @NSManaged public var id: UUID?
    @NSManaged public var isPartial: Bool
    @NSManaged public var notes: String?
    @NSManaged public var paidDate: Date?
    @NSManaged public var paymentMethodRaw: String?
    @NSManaged public var paymentTypeRaw: String?
    @NSManaged public var contract: Contract?

}

extension Payment : Identifiable {

}

