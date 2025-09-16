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
