import Foundation
import CoreData

@objc(PaymentSchedule)
public class PaymentSchedule: NSManagedObject {
    
    var isOverdue: Bool {
        return !isPaid && dueDate < Date()
    }
    
    var daysOverdue: Int {
        guard isOverdue else { return 0 }
        return Calendar.current.dateComponents([.day], from: dueDate, to: Date()).day ?? 0
    }
    
    var status: PaymentStatus {
        if isPaid {
            return .paid
        } else if isOverdue {
            return .overdue
        } else {
            let daysUntilDue = Calendar.current.dateComponents([.day], from: Date(), to: dueDate).day ?? 0
            return daysUntilDue <= 3 ? .dueSoon : .upcoming
        }
    }
    
    func markAsPaid(on date: Date = Date()) {
        isPaid = true
        paidDate = date
    }
}

enum PaymentStatus {
    case paid
    case overdue
    case dueSoon
    case upcoming
    
    var color: String {
        switch self {
        case .paid: return "green"
        case .overdue: return "red"
        case .dueSoon: return "orange"
        case .upcoming: return "blue"
        }
    }
    
    var localizedName: String {
        switch self {
        case .paid:
            return NSLocalizedString("Paid", comment: "Payment status: paid")
        case .overdue:
            return NSLocalizedString("Overdue", comment: "Payment status: overdue")
        case .dueSoon:
            return NSLocalizedString("Due Soon", comment: "Payment status: due soon")
        case .upcoming:
            return NSLocalizedString("Upcoming", comment: "Payment status: upcoming")
        }
    }
}

// MARK: - Convenience Initializer
extension PaymentSchedule {
    convenience init(context: NSManagedObjectContext, contract: Contract, dueDate: Date, amount: Decimal) {
        self.init(context: context)
        self.id = UUID()
        self.contract = contract
        self.dueDate = dueDate
        self.amount = amount
        self.isPaid = false
    }
}
