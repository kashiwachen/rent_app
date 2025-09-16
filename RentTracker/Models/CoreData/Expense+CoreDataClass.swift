import Foundation
import CoreData

@objc(Expense)
public class Expense: NSManagedObject {
    
    var category: ExpenseCategory {
        get {
            return ExpenseCategory(rawValue: categoryRaw ?? ExpenseCategory.maintenance.rawValue) ?? .maintenance
        }
        set {
            categoryRaw = newValue.rawValue
        }
    }
}

// MARK: - Convenience Initializer
extension Expense {
    convenience init(context: NSManagedObjectContext,
                    property: Property,
                    amount: Decimal,
                    category: ExpenseCategory,
                    description: String,
                    date: Date = Date()) {
        self.init(context: context)
        self.id = UUID()
        self.property = property
        self.amount = amount
        self.category = category
        self.expenseDescription = description
        self.date = date
    }
}
