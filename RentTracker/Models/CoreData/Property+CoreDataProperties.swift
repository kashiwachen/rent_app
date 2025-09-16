import Foundation
import CoreData

extension Property {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Property> {
        return NSFetchRequest<Property>(entityName: "Property")
    }

    @NSManaged public var address: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var propertyTypeRaw: String?
    @NSManaged public var contracts: NSSet?
    @NSManaged public var expenses: NSSet?

}

// MARK: Generated accessors for contracts
extension Property {

    @objc(addContractsObject:)
    @NSManaged public func addToContracts(_ value: Contract)

    @objc(removeContractsObject:)
    @NSManaged public func removeFromContracts(_ value: Contract)

    @objc(addContracts:)
    @NSManaged public func addToContracts(_ values: NSSet)

    @objc(removeContracts:)
    @NSManaged public func removeFromContracts(_ values: NSSet)

}

// MARK: Generated accessors for expenses
extension Property {

    @objc(addExpensesObject:)
    @NSManaged public func addToExpenses(_ value: Expense)

    @objc(removeExpensesObject:)
    @NSManaged public func removeFromExpenses(_ value: Expense)

    @objc(addExpenses:)
    @NSManaged public func addToExpenses(_ values: NSSet)

    @objc(removeExpenses:)
    @NSManaged public func removeFromExpenses(_ values: NSSet)

}

extension Property : Identifiable {

}
