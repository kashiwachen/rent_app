import Foundation
import CoreData

class CoreDataService: ObservableObject {
    static let shared = CoreDataService()

    private let persistenceController = PersistenceController.shared

    var context: NSManagedObjectContext {
        return persistenceController.container.viewContext
    }

    private init() {}

    // MARK: - Save Context
    func save() {
        persistenceController.save()
    }

    // MARK: - Property Operations
    func fetchProperties() -> [Property] {
        let request: NSFetchRequest<Property> = Property.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Property.name, ascending: true)]

        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch properties: \(error)")
            return []
        }
    }

    func createProperty(name: String, address: String, type: PropertyType) -> Property {
        let property = Property(context: context, name: name, address: address, type: type)
        save()
        return property
    }

    func deleteProperty(_ property: Property) {
        context.delete(property)
        save()
    }

    // MARK: - Tenant Operations
    func fetchTenants() -> [Tenant] {
        let request: NSFetchRequest<Tenant> = Tenant.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Tenant.name, ascending: true)]

        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch tenants: \(error)")
            return []
        }
    }

    func createTenant(name: String, phone: String, email: String? = nil) -> Tenant {
        let tenant = Tenant(context: context, name: name, phone: phone, email: email)
        save()
        return tenant
    }

    func deleteTenant(_ tenant: Tenant) {
        context.delete(tenant)
        save()
    }

    // MARK: - Contract Operations
    func fetchContracts() -> [Contract] {
        let request: NSFetchRequest<Contract> = Contract.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Contract.startDate, ascending: false)]

        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch contracts: \(error)")
            return []
        }
    }

    func fetchActiveContracts() -> [Contract] {
        let request: NSFetchRequest<Contract> = Contract.fetchRequest()
        request.predicate = NSPredicate(format: "isActive == YES")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Contract.startDate, ascending: false)]

        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch active contracts: \(error)")
            return []
        }
    }

    func createContract(property: Property, tenant: Tenant, startDate: Date, endDate: Date, rentAmount: Decimal, paymentCycle: PaymentCycle, depositAmount: Decimal) -> Contract {
        // Deactivate existing active contracts for this property
        if let existingContract = property.activeContract {
            existingContract.isActive = false
        }

        let contract = Contract(context: context, property: property, tenant: tenant, startDate: startDate, endDate: endDate, rentAmount: rentAmount, paymentCycle: paymentCycle, depositAmount: depositAmount)

        // Schedule notifications for all payment schedules
        if let schedules = contract.paymentSchedules?.allObjects as? [PaymentSchedule] {
            for schedule in schedules {
                NotificationService.shared.scheduleRentDueNotification(for: schedule)
            }
        }

        save()
        return contract
    }

    func deleteContract(_ contract: Contract) {
        // Cancel all notifications for this contract
        if let schedules = contract.paymentSchedules?.allObjects as? [PaymentSchedule] {
            for schedule in schedules {
                NotificationService.shared.cancelNotification(for: schedule.id?.uuidString ?? "")
            }
        }

        context.delete(contract)
        save()
    }

    // MARK: - Payment Operations
    func fetchOverduePayments() -> [PaymentSchedule] {
        let request: NSFetchRequest<PaymentSchedule> = PaymentSchedule.fetchRequest()
        let today = Date()
        request.predicate = NSPredicate(format: "isPaid == NO AND dueDate < %@", today as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \PaymentSchedule.dueDate, ascending: true)]

        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch overdue payments: \(error)")
            return []
        }
    }

    func fetchUpcomingPayments(days: Int = 7) -> [PaymentSchedule] {
        let request: NSFetchRequest<PaymentSchedule> = PaymentSchedule.fetchRequest()
        let today = Date()
        let futureDate = Calendar.current.date(byAdding: .day, value: days, to: today) ?? today

        request.predicate = NSPredicate(format: "isPaid == NO AND dueDate >= %@ AND dueDate <= %@", today as NSDate, futureDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \PaymentSchedule.dueDate, ascending: true)]

        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch upcoming payments: \(error)")
            return []
        }
    }

    func markPaymentAsPaid(_ paymentSchedule: PaymentSchedule, on date: Date = Date()) {
        paymentSchedule.markAsPaid(on: date)

        // Cancel notifications for this payment
        NotificationService.shared.cancelNotification(for: paymentSchedule.id?.uuidString ?? "")

        save()
    }

    func createPayment(contract: Contract, amount: Decimal, dueDate: Date, paymentType: PaymentType, paymentMethod: PaymentMethod, paidDate: Date? = nil, isPartial: Bool = false, notes: String? = nil) -> Payment {
        let payment = Payment(context: context, contract: contract, amount: amount, dueDate: dueDate, paymentType: paymentType, paymentMethod: paymentMethod, paidDate: paidDate, isPartial: isPartial, notes: notes)
        save()
        return payment
    }

    // MARK: - Expense Operations
    func fetchExpenses(for property: Property? = nil) -> [Expense] {
        let request: NSFetchRequest<Expense> = Expense.fetchRequest()

        if let property = property {
            request.predicate = NSPredicate(format: "property == %@", property)
        }

        request.sortDescriptors = [NSSortDescriptor(keyPath: \Expense.date, ascending: false)]

        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch expenses: \(error)")
            return []
        }
    }

    func createExpense(property: Property, amount: Decimal, category: ExpenseCategory, description: String, date: Date = Date()) -> Expense {
        let expense = Expense(context: context, property: property, amount: amount, category: category, description: description, date: date)
        save()
        return expense
    }

    func deleteExpense(_ expense: Expense) {
        context.delete(expense)
        save()
    }

    // MARK: - Reporting Operations
    func calculateYearlyIncome(year: Int) -> Decimal {
        let calendar = Calendar.current
        guard let startDate = calendar.date(from: DateComponents(year: year, month: 1, day: 1)),
              let endDate = calendar.date(from: DateComponents(year: year + 1, month: 1, day: 1)) else {
            print("Failed to create date range for year \(year)")
            return Decimal.zero
        }

        let request: NSFetchRequest<Payment> = Payment.fetchRequest()
        request.predicate = NSPredicate(format: "paidDate >= %@ AND paidDate < %@ AND paymentTypeRaw IN %@",
                                       startDate as NSDate,
                                       endDate as NSDate,
                                       [PaymentType.rent.rawValue, PaymentType.lateFee.rawValue, PaymentType.deposit.rawValue])

        do {
            let payments = try context.fetch(request)
            return payments.reduce(0) { $0 + $1.amount }
        } catch {
            print("Failed to calculate yearly income: \(error.localizedDescription)")
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
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", startDate as NSDate, endDate as NSDate)

        do {
            let expenses = try context.fetch(request)
            return expenses.reduce(0) { $0 + $1.amount }
        } catch {
            print("Failed to calculate yearly expenses: \(error.localizedDescription)")
            return Decimal.zero
        }
    }
    
    func calculateVacancyRate() -> Double {
        let properties = fetchProperties()
        guard !properties.isEmpty else { return 0 }
        
        let vacantProperties = properties.filter { $0.isVacant }
        return Double(vacantProperties.count) / Double(properties.count) * 100
    }
    
    // MARK: - Backup Operations
    func createBackup() -> URL? {
        return persistenceController.createBackup()
    }
    
    func restoreFromBackup(_ url: URL) -> Bool {
        return persistenceController.restoreFromBackup(url)
    }
}
