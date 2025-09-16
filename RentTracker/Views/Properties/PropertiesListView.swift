import SwiftUI

struct PropertiesListView: View {
    @EnvironmentObject var propertyViewModel: PropertyViewModel
    @EnvironmentObject var contractViewModel: ContractViewModel
    @State private var showingAddProperty = false
    @State private var searchText = ""
    
    var filteredProperties: [Property] {
        if searchText.isEmpty {
            return propertyViewModel.properties
        } else {
            return propertyViewModel.properties.filter { property in
                (property.name?.localizedCaseInsensitiveContains(searchText) == true) ||
                (property.address?.localizedCaseInsensitiveContains(searchText) == true) ||
                (property.currentTenant?.name?.localizedCaseInsensitiveContains(searchText) == true)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                // Properties with overdue payments (priority)
                if !propertyViewModel.getPropertiesWithOverduePayments().isEmpty {
                    Section("⚠️ Properties with Overdue Payments") {
                        ForEach(propertyViewModel.getPropertiesWithOverduePayments(), id: \.id) { property in
                            NavigationLink(destination: PropertyDetailView(property: property)) {
                                PropertyRowView(property: property, showOverdueWarning: true)
                            }
                        }
                    }
                }
                
                // All properties
                Section("All Properties") {
                    ForEach(filteredProperties, id: \.id) { property in
                        NavigationLink(destination: PropertyDetailView(property: property)) {
                            PropertyRowView(property: property, showOverdueWarning: false)
                        }
                    }
                    .onDelete(perform: deleteProperties)
                }
            }
            .searchable(text: $searchText, prompt: "Search properties, addresses, or tenants")
            .navigationTitle("Properties")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddProperty = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .refreshable {
                propertyViewModel.loadProperties()
            }
            .sheet(isPresented: $showingAddProperty) {
                AddPropertyView()
                    .environmentObject(propertyViewModel)
            }
        }
    }
    
    private func deleteProperties(offsets: IndexSet) {
        for index in offsets {
            let property = filteredProperties[index]
            propertyViewModel.deleteProperty(property)
        }
    }
}

struct PropertyRowView: View {
    let property: Property
    let showOverdueWarning: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(property.name ?? "Unknown Property")
                        .font(.headline)
                    
                    if showOverdueWarning {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    Spacer()
                    
                    // Property type badge
                    Text(property.propertyType.localizedName)
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .cornerRadius(4)
                }
                
                Text(property.address ?? "No address")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    if let tenant = property.currentTenant {
                        Label(tenant.name ?? "Unknown Tenant", systemImage: "person.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    } else {
                        Label("Vacant", systemImage: "house")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    
                    Spacer()
                    
                    // Net income display
                    Text("Net: \(formatAmount(property.netIncome))")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(property.netIncome >= 0 ? .green : .red)
                }
                
                // Overdue amount if applicable
                if showOverdueWarning && !property.overduePayments.isEmpty {
                    let overdueAmount = property.overduePayments.reduce(0) { $0 + $1.amount }
                    Text("Overdue: \(formatAmount(overdueAmount))")
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
}

struct PropertyDetailView: View {
    let property: Property
    @EnvironmentObject var contractViewModel: ContractViewModel
    @State private var showingAddContract = false
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                // Property Info
                propertyInfoSection
                
                // Current Tenant & Contract
                if let activeContract = property.activeContract {
                    currentContractSection(activeContract)
                } else {
                    vacantPropertySection
                }
                
                // Financial Summary
                financialSummarySection
                
                // Contract History
                contractHistorySection
                
                // Recent Expenses
                recentExpensesSection
            }
            .padding()
        }
        .navigationTitle(property.name ?? "Property")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Add Contract") {
                    showingAddContract = true
                }
                .disabled(!property.isVacant)
            }
        }
        .sheet(isPresented: $showingAddContract) {
            AddContractView(property: property)
                .environmentObject(contractViewModel)
        }
    }
    
    private var propertyInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Property Information")
                .font(.headline)
            
            InfoRow(label: "Address", value: property.address ?? "No address")
            InfoRow(label: "Type", value: property.propertyType.localizedName)
            InfoRow(label: "Status", value: property.isVacant ? "Vacant" : "Occupied")
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func currentContractSection(_ contract: Contract) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current Contract")
                .font(.headline)
            
            if let tenant = contract.tenant {
                InfoRow(label: "Tenant", value: tenant.name ?? "Unknown")
                InfoRow(label: "Phone", value: tenant.phone ?? "No phone")
                if let email = tenant.email {
                    InfoRow(label: "Email", value: email)
                }
            }
            
            InfoRow(label: "Rent Amount", value: formatAmount(contract.rentAmount))
            InfoRow(label: "Payment Cycle", value: contract.paymentCycle.localizedName)
            InfoRow(label: "Contract Period", value: "\(formatDate(contract.startDate)) - \(formatDate(contract.endDate))")
            
            if contract.overdueAmount > 0 {
                InfoRow(label: "Overdue Amount", value: formatAmount(contract.overdueAmount))
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var vacantPropertySection: some View {
        VStack(spacing: 12) {
            Image(systemName: "house.slash")
                .font(.largeTitle)
                .foregroundColor(.orange)
            
            Text("Property is Vacant")
                .font(.headline)
                .foregroundColor(.orange)
            
            Text("Add a new contract to start tracking rent payments")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var financialSummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Financial Summary")
                .font(.headline)
            
            HStack {
                FinancialCard(
                    title: "Total Income",
                    amount: property.totalIncome,
                    color: .green
                )
                
                FinancialCard(
                    title: "Total Expenses",
                    amount: property.totalExpenses,
                    color: .red
                )
            }
            
            FinancialCard(
                title: "Net Income",
                amount: property.netIncome,
                color: property.netIncome >= 0 ? .green : .red
            )
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var contractHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Contract History")
                .font(.headline)
            
            let contracts = contractViewModel.getContractsForProperty(property)
            
            if contracts.isEmpty {
                Text("No contracts found")
                    .foregroundColor(.secondary)
            } else {
                ForEach(contracts.prefix(5), id: \.id) { contract in
                    ContractHistoryRow(contract: contract)
                }
                
                if contracts.count > 5 {
                    Text("... and \(contracts.count - 5) more")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var recentExpensesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Expenses")
                .font(.headline)
            
            // This would show recent expenses for the property
            // Implementation would require expense data
            Text("No recent expenses")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func formatAmount(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "¥"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: amount as NSDecimalNumber) ?? "¥0.00"
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

struct FinancialCard: View {
    let title: String
    let amount: Decimal
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(formatAmount(amount))
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
    
    private func formatAmount(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "¥"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: amount as NSDecimalNumber) ?? "¥0.00"
    }
}

struct ContractHistoryRow: View {
    let contract: Contract
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(contract.tenant?.name ?? "Unknown Tenant")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(formatDate(contract.startDate)) - \(formatDate(contract.endDate))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatAmount(contract.rentAmount))
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(contract.isActive ? "Active" : "Ended")
                    .font(.caption)
                    .foregroundColor(contract.isActive ? .green : .secondary)
            }
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
    PropertiesListView()
        .environmentObject(PropertyViewModel())
        .environmentObject(ContractViewModel())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
