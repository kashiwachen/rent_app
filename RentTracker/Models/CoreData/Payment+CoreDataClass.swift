import Foundation
import CoreData

@objc(Payment)
public class Payment: NSManagedObject {
    
    var paymentType: PaymentType {
        get {
            return PaymentType(rawValue: paymentTypeRaw ?? PaymentType.rent.rawValue) ?? .rent
        }
        set {
            paymentTypeRaw = newValue.rawValue
        }
    }
    
    var paymentMethod: PaymentMethod {
        get {
            return PaymentMethod(rawValue: paymentMethodRaw ?? PaymentMethod.bankTransfer.rawValue) ?? .bankTransfer
        }
        set {
            paymentMethodRaw = newValue.rawValue
        }
    }
    
    var isOverdue: Bool {
        return paidDate == nil && dueDate < Date()
    }
    
    var daysOverdue: Int {
        guard isOverdue else { return 0 }
        return Calendar.current.dateComponents([.day], from: dueDate, to: Date()).day ?? 0
    }
}

// MARK: - Convenience Initializer
extension Payment {
    convenience init(context: NSManagedObjectContext,
                    contract: Contract,
                    amount: Decimal,
                    dueDate: Date,
                    paymentType: PaymentType,
                    paymentMethod: PaymentMethod,
                    paidDate: Date? = nil,
                    isPartial: Bool = false,
                    notes: String? = nil) {
        self.init(context: context)
        self.id = UUID()
        self.contract = contract
        self.amount = amount
        self.dueDate = dueDate
        self.paymentType = paymentType
        self.paymentMethod = paymentMethod
        self.paidDate = paidDate
        self.isPartial = isPartial
        self.notes = notes
    }
}
