import Foundation
import CoreData

extension Tenant {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Tenant> {
        return NSFetchRequest<Tenant>(entityName: "Tenant")
    }

    @NSManaged public var createdAt: Date?
    @NSManaged public var email: String?
    @NSManaged public var id: UUID?
    @NSManaged public var name: String!
    @NSManaged public var phone: String!
    @NSManaged public var contracts: NSSet?

}

// MARK: Generated accessors for contracts
extension Tenant {

    @objc(addContractsObject:)
    @NSManaged public func addToContracts(_ value: Contract)

    @objc(removeContractsObject:)
    @NSManaged public func removeFromContracts(_ value: Contract)

    @objc(addContracts:)
    @NSManaged public func addToContracts(_ values: NSSet)

    @objc(removeContracts:)
    @NSManaged public func removeFromContracts(_ values: NSSet)

}

extension Tenant : Identifiable {

}
