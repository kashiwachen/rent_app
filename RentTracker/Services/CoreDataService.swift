import Foundation
import CoreData

class CoreDataService {
    static let shared = CoreDataService()

    private init() {}

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "RentTracker")
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Core Data failed to load: \(error.localizedDescription)")
            }
        }
        return container
    }()

    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    func save() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Failed to save context: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Yearly Income/Expense Calculations

    func calculateYearlyIncome(year: Int) -> Decimal {
        let calendar = Calendar.current
        guard let startDate = calendar.date(from: DateComponents(year: year, month: 1, day: 1)),
              let endDate = calendar.date(from: DateComponents(year: year + 1, month: 1, day: 1)) else {
            print("Failed to create date range for year \(year)")
            return Decimal.zero
        }

        let request: NSFetchRequest<Payment> = Payment.fetchRequest()
        request.predicate = NSPredicate(format: "paymentDate >= %@ AND paymentDate < %@ AND paymentType.name LIKE 'Rent'",
                                       startDate as NSDate, endDate as NSDate)

        do {
            let payments = try context.fetch(request)
            return payments.reduce(Decimal.zero) { result, payment in
                result + (payment.amount?.decimalValue ?? 0)
            }
        } catch {
            print("Failed to fetch yearly income: \(error.localizedDescription)")
            return Decimal.zero
        }
    }

    func calculateYearlyExpenses(year: Int) -> Decimal {
        let calendar = Calendar.current
        guard let startDate = calendar.date(from: DateComponents(year: year, month: 1, day: 1)),
              let endDate = calendar.date(from: DateComponents(year: year + 1, month: 1, day: 1)) else {
            print("Failed to create date range for year \(year)")
            return Decimal.zero
        }

        let request: NSFetchRequest<Expense> = Expense.fetchRequest()
        request.predicate = NSPredicate(format: "expenseDate >= %@ AND expenseDate < %@",
                                       startDate as NSDate, endDate as NSDate)

        do {
            let expenses = try context.fetch(request)
            return expenses.reduce(Decimal.zero) { result, expense in
                result + (expense.amount?.decimalValue ?? 0)
            }
        } catch {
            print("Failed to fetch yearly expenses: \(error.localizedDescription)")
            return Decimal.zero
        }
    }
}