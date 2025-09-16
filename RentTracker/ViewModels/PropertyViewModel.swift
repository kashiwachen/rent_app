import Foundation
import CoreData
import Combine

class PropertyViewModel: ObservableObject {
    @Published var properties: [Property] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let coreDataService = CoreDataService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadProperties()
    }
    
    func loadProperties() {
        isLoading = true
        errorMessage = nil
        
        DispatchQueue.main.async {
            self.properties = self.coreDataService.fetchProperties()
            self.isLoading = false
        }
    }
    
    func addProperty(name: String, address: String, type: PropertyType) {
        guard !name.isEmpty, !address.isEmpty else {
            errorMessage = NSLocalizedString("Please fill in all required fields", comment: "Validation error")
            return
        }
        
        let _ = coreDataService.createProperty(name: name, address: address, type: type)
        loadProperties()
    }
    
    func deleteProperty(_ property: Property) {
        coreDataService.deleteProperty(property)
        loadProperties()
    }
    
    func getPropertiesWithOverduePayments() -> [Property] {
        return properties.filter { !$0.overduePayments.isEmpty }
    }
    
    func getVacantProperties() -> [Property] {
        return properties.filter { $0.isVacant }
    }
    
    func getOccupiedProperties() -> [Property] {
        return properties.filter { !$0.isVacant }
    }
    
    func getTotalIncome() -> Decimal {
        return properties.reduce(0) { $0 + $1.totalIncome }
    }
    
    func getTotalExpenses() -> Decimal {
        return properties.reduce(0) { $0 + $1.totalExpenses }
    }
    
    func getNetIncome() -> Decimal {
        return getTotalIncome() - getTotalExpenses()
    }
    
    func getVacancyRate() -> Double {
        return coreDataService.calculateVacancyRate()
    }
}
