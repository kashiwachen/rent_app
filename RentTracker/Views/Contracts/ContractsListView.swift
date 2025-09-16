import SwiftUI

struct ContractsListView: View {
    @EnvironmentObject var contractViewModel: ContractViewModel
    @EnvironmentObject var propertyViewModel: PropertyViewModel
    @State private var showingAddContract = false
    @State private var selectedProperty: Property?
    
    var body: some View {
        NavigationView {
            List {
                // Active Contracts
                if !contractViewModel.activeContracts.isEmpty {
                    Section("Active Contracts") {
                        ForEach(contractViewModel.activeContracts, id: \.id) { contract in
                            ContractRowView(contract: contract)
                        }
                    }
                }
                
                // Expiring Soon
                let expiringContracts = contractViewModel.getExpiringContracts()
                if !expiringContracts.isEmpty {
                    Section("Expiring Soon") {
                        ForEach(expiringContracts, id: \.id) { contract in
                            ContractRowView(contract: contract, showExpiryWarning: true)
                        }
                    }
                }
                
                // All Contracts
                Section("All Contracts") {
                    ForEach(contractViewModel.contracts, id: \.id) { contract in
                        ContractRowView(contract: contract)
                    }
                    .onDelete(perform: deleteContracts)
                }
            }
            .navigationTitle("Contracts")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddContract = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .refreshable {
                contractViewModel.loadContracts()
            }
            .sheet(isPresented: $showingAddContract) {
                AddContractView(property: selectedProperty)
                    .environmentObject(contractViewModel)
            }
        }
    }
    
    private func deleteContracts(offsets: IndexSet) {
        for index in offsets {
            let contract = contractViewModel.contracts[index]
            contractViewModel.deleteContract(contract)
        }
    }
}

struct ContractRowView: View {
    let contract: Contract
    let showExpiryWarning: Bool
    
    init(contract: Contract, showExpiryWarning: Bool = false) {
        self.contract = contract
        self.showExpiryWarning = showExpiryWarning
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(contract.property?.name ?? "Unknown Property")
                        .font(.headline)
                    
                    if showExpiryWarning {
                        Image(systemName: "clock.badge.exclamationmark")
                            .foregroundColor(.orange)
                            .font(.caption)
                    }
                    
                    Spacer()
                    
                    // Status badge
                    let status = ContractViewModel().getContractStatus(contract)
                    Text(status.localizedName)
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color(status.color).opacity(0.2))
                        .foregroundColor(Color(status.color))
                        .cornerRadius(4)
                }
                
                Text(contract.tenant?.name ?? "Unknown Tenant")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text(formatAmount(contract.rentAmount))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text("• \(contract.paymentCycle.localizedName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text("\(formatDate(contract.startDate)) - \(formatDate(contract.endDate))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if contract.overdueAmount > 0 {
                    Text("Overdue: \(formatAmount(contract.overdueAmount))")
                        .font(.caption)
                        .foregroundColor(.red)
                        .fontWeight(.medium)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    private func formatAmount(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "¥"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: amount as NSDecimalNumber) ?? "¥0"
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    ContractsListView()
        .environmentObject(ContractViewModel())
        .environmentObject(PropertyViewModel())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
