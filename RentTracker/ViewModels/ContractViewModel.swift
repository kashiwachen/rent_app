import Foundation
import CoreData
import Combine

class ContractViewModel: ObservableObject {
    @Published var contracts: [Contract] = []
    @Published var activeContracts: [Contract] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let coreDataService = CoreDataService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadContracts()
    }
    
    func loadContracts() {
        isLoading = true
        errorMessage = nil
        
        DispatchQueue.main.async {
            self.contracts = self.coreDataService.fetchContracts()
            self.activeContracts = self.coreDataService.fetchActiveContracts()
            self.isLoading = false
        }
    }
    
    func addContract(property: Property, tenant: Tenant, startDate: Date, endDate: Date, rentAmount: Decimal, paymentCycle: PaymentCycle, depositAmount: Decimal) {
        guard startDate < endDate else {
            errorMessage = NSLocalizedString("End date must be after start date", comment: "Validation error")
            return
        }
        
        guard rentAmount > 0 else {
            errorMessage = NSLocalizedString("Rent amount must be greater than zero", comment: "Validation error")
            return
        }
        
        let _ = coreDataService.createContract(
            property: property,
            tenant: tenant,
            startDate: startDate,
            endDate: endDate,
            rentAmount: rentAmount,
            paymentCycle: paymentCycle,
            depositAmount: depositAmount
        )
        
        loadContracts()
    }
    
    func deleteContract(_ contract: Contract) {
        coreDataService.deleteContract(contract)
        loadContracts()
    }
    
    func endContract(_ contract: Contract) {
        contract.isActive = false
        contract.endDate = Date()
        coreDataService.save()
        loadContracts()
    }
    
    func renewContract(_ contract: Contract, newEndDate: Date, newRentAmount: Decimal? = nil) {
        contract.endDate = newEndDate
        if let newAmount = newRentAmount {
            contract.rentAmount = newAmount
        }
        
        // Regenerate payment schedule
        contract.generatePaymentSchedule()
        
        coreDataService.save()
        loadContracts()
    }
    
    func getContractsForProperty(_ property: Property) -> [Contract] {
        return contracts.filter { $0.property == property }
    }
    
    func getContractsForTenant(_ tenant: Tenant) -> [Contract] {
        return contracts.filter { $0.tenant == tenant }
    }
    
    func getExpiringContracts(days: Int = 30) -> [Contract] {
        let futureDate = Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
        return activeContracts.filter { $0.endDate <= futureDate }
    }
    
    func getContractStatus(_ contract: Contract) -> ContractStatus {
        let today = Date()
        
        if !contract.isActive {
            return .ended
        } else if contract.endDate < today {
            return .expired
        } else if contract.startDate > today {
            return .upcoming
        } else {
            let daysUntilExpiry = Calendar.current.dateComponents([.day], from: today, to: contract.endDate).day ?? 0
            return daysUntilExpiry <= 30 ? .expiringSoon : .active
        }
    }
    
    func formatContractDuration(_ contract: Contract) -> String {
        let components = Calendar.current.dateComponents([.month], from: contract.startDate, to: contract.endDate)
        let months = components.month ?? 0
        
        if months >= 12 {
            let years = months / 12
            let remainingMonths = months % 12
            if remainingMonths == 0 {
                return String(format: NSLocalizedString("%d year(s)", comment: "Contract duration in years"), years)
            } else {
                return String(format: NSLocalizedString("%d year(s) %d month(s)", comment: "Contract duration in years and months"), years, remainingMonths)
            }
        } else {
            return String(format: NSLocalizedString("%d month(s)", comment: "Contract duration in months"), months)
        }
    }
}

enum ContractStatus {
    case active
    case expiringSoon
    case expired
    case ended
    case upcoming
    
    var localizedName: String {
        switch self {
        case .active:
            return NSLocalizedString("Active", comment: "Contract status: active")
        case .expiringSoon:
            return NSLocalizedString("Expiring Soon", comment: "Contract status: expiring soon")
        case .expired:
            return NSLocalizedString("Expired", comment: "Contract status: expired")
        case .ended:
            return NSLocalizedString("Ended", comment: "Contract status: ended")
        case .upcoming:
            return NSLocalizedString("Upcoming", comment: "Contract status: upcoming")
        }
    }
    
    var color: String {
        switch self {
        case .active: return "green"
        case .expiringSoon: return "orange"
        case .expired: return "red"
        case .ended: return "gray"
        case .upcoming: return "blue"
        }
    }
}
