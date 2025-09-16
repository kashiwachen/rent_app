import Foundation
import CoreData
import Combine

class PaymentViewModel: ObservableObject {
    @Published var overduePayments: [PaymentSchedule] = []
    @Published var upcomingPayments: [PaymentSchedule] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let coreDataService = CoreDataService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadPayments()
    }
    
    func loadPayments() {
        isLoading = true
        errorMessage = nil
        
        DispatchQueue.main.async {
            self.overduePayments = self.coreDataService.fetchOverduePayments()
            self.upcomingPayments = self.coreDataService.fetchUpcomingPayments()
            self.isLoading = false
        }
    }
    
    func markPaymentAsPaid(_ paymentSchedule: PaymentSchedule, on date: Date = Date()) {
        coreDataService.markPaymentAsPaid(paymentSchedule, on: date)
        loadPayments()
    }
    
    func addPayment(contract: Contract, amount: Decimal, dueDate: Date, paymentType: PaymentType, paymentMethod: PaymentMethod, paidDate: Date? = nil, isPartial: Bool = false, notes: String? = nil) {
        let _ = coreDataService.createPayment(
            contract: contract,
            amount: amount,
            dueDate: dueDate,
            paymentType: paymentType,
            paymentMethod: paymentMethod,
            paidDate: paidDate,
            isPartial: isPartial,
            notes: notes
        )
        loadPayments()
    }
    
    func getTotalOverdueAmount() -> Decimal {
        return overduePayments.reduce(0) { $0 + $1.amount }
    }
    
    func getOverduePaymentsCount() -> Int {
        return overduePayments.count
    }
    
    func getUpcomingPaymentsCount() -> Int {
        return upcomingPayments.count
    }
    
    func getPaymentsByProperty() -> [Property: [PaymentSchedule]] {
        var paymentsByProperty: [Property: [PaymentSchedule]] = [:]
        
        let allPayments = overduePayments + upcomingPayments
        
        for payment in allPayments {
            if let property = payment.contract?.property {
                if paymentsByProperty[property] == nil {
                    paymentsByProperty[property] = []
                }
                paymentsByProperty[property]?.append(payment)
            }
        }
        
        return paymentsByProperty
    }
    
    func getPaymentStatus(for paymentSchedule: PaymentSchedule) -> PaymentStatus {
        return paymentSchedule.status
    }
    
    func formatAmount(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "¥"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: amount as NSDecimalNumber) ?? "¥0.00"
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    func getDaysOverdue(for paymentSchedule: PaymentSchedule) -> Int {
        return paymentSchedule.daysOverdue
    }
}
