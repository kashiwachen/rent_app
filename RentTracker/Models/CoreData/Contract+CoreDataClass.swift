import Foundation
import CoreData

@objc(Contract)
public class Contract: NSManagedObject {
    
    var paymentCycle: PaymentCycle {
        get {
            return PaymentCycle(rawValue: paymentCycleRaw ?? PaymentCycle.monthly.rawValue) ?? .monthly
        }
        set {
            paymentCycleRaw = newValue.rawValue
        }
    }
    
    var nextPaymentDue: Date? {
        guard let schedules = paymentSchedules?.allObjects as? [PaymentSchedule] else { return nil }
        let unpaidSchedules = schedules.filter { !$0.isPaid }.sorted { $0.dueDate < $1.dueDate }
        return unpaidSchedules.first?.dueDate
    }
    
    var overdueAmount: Decimal {
        guard let schedules = paymentSchedules?.allObjects as? [PaymentSchedule] else { return 0 }
        let today = Date()
        let overdueSchedules = schedules.filter { !$0.isPaid && $0.dueDate < today }
        return overdueSchedules.reduce(0) { $0 + $1.amount }
    }
    
    var totalPaid: Decimal {
        guard let payments = payments?.allObjects as? [Payment] else { return 0 }
        return payments.filter { $0.paymentType.isIncome }.reduce(0) { $0 + $1.amount }
    }
    
    var isOverdue: Bool {
        return overdueAmount > 0
    }
    
    var daysOverdue: Int {
        guard let nextDue = nextPaymentDue, nextDue < Date() else { return 0 }
        return Calendar.current.dateComponents([.day], from: nextDue, to: Date()).day ?? 0
    }
    
    func generatePaymentSchedule() {
        guard let context = managedObjectContext else { return }
        
        // Remove existing schedules
        if let existingSchedules = paymentSchedules?.allObjects as? [PaymentSchedule] {
            existingSchedules.forEach { context.delete($0) }
        }
        
        var currentDate = startDate
        let calendar = Calendar.current
        
        while currentDate <= endDate {
            let schedule = PaymentSchedule(context: context)
            schedule.id = UUID()
            schedule.dueDate = currentDate
            schedule.amount = rentAmount
            schedule.isPaid = false
            schedule.contract = self
            
            // Move to next payment date based on cycle
            currentDate = calendar.date(byAdding: .month, value: paymentCycle.monthsInterval, to: currentDate) ?? endDate
        }
    }
}

// MARK: - Convenience Initializer
extension Contract {
    convenience init(context: NSManagedObjectContext, 
                    property: Property, 
                    tenant: Tenant, 
                    startDate: Date, 
                    endDate: Date, 
                    rentAmount: Decimal, 
                    paymentCycle: PaymentCycle, 
                    depositAmount: Decimal) {
        self.init(context: context)
        self.id = UUID()
        self.property = property
        self.tenant = tenant
        self.startDate = startDate
        self.endDate = endDate
        self.rentAmount = rentAmount
        self.paymentCycle = paymentCycle
        self.depositAmount = depositAmount
        self.isActive = true
        self.createdAt = Date()
        
        // Generate payment schedule
        generatePaymentSchedule()
    }
}
