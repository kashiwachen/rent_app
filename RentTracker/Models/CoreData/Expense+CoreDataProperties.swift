import Foundation
import CoreData

extension Expense {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Expense> {
        return NSFetchRequest<Expense>(entityName: "Expense")
    }

    @NSManaged public var amount: NSDecimalNumber!
    @NSManaged public var categoryRaw: String?
    @NSManaged public var date: Date!
    @NSManaged public var expenseDescription: String!
    @NSManaged public var id: UUID?
    @NSManaged public var property: Property?

}

extension Expense : Identifiable {

}

// MARK: - Decimal Conversion
extension Expense {
    var amount: Decimal {
        get { amount?.decimalValue ?? 0 }
        set { amount = NSDecimalNumber(decimal: newValue) }
    }
}
