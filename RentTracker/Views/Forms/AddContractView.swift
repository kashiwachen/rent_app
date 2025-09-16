import SwiftUI

struct AddContractView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var contractViewModel: ContractViewModel
    
    let property: Property?
    
    @State private var selectedProperty: Property?
    @State private var tenantName = ""
    @State private var tenantPhone = ""
    @State private var tenantEmail = ""
    @State private var startDate = Date()
    @State private var endDate = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
    @State private var rentAmount = ""
    @State private var paymentCycle = PaymentCycle.monthly
    @State private var depositAmount = ""
    
    @State private var showingError = false
    @State private var errorMessage = ""
    
    private var properties: [Property] {
        return CoreDataService.shared.fetchProperties().filter { $0.isVacant }
    }
    
    init(property: Property? = nil) {
        self.property = property
        self._selectedProperty = State(initialValue: property)
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Property Selection (if not pre-selected)
                if property == nil {
                    Section("Property") {
                        Picker("Select Property", selection: $selectedProperty) {
                            Text("Select a property").tag(nil as Property?)
                            ForEach(properties, id: \.id) { property in
                                Text(property.name ?? "Unknown").tag(property as Property?)
                            }
                        }
                    }
                }
                
                // Tenant Information
                Section("Tenant Information") {
                    TextField("Tenant Name", text: $tenantName)
                        .textInputAutocapitalization(.words)
                    
                    TextField("Phone Number", text: $tenantPhone)
                        .keyboardType(.phonePad)
                    
                    TextField("Email (Optional)", text: $tenantEmail)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                }
                
                // Contract Details
                Section("Contract Details") {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                    
                    HStack {
                        Text("Rent Amount")
                        Spacer()
                        TextField("0", text: $rentAmount)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("¥")
                    }
                    
                    Picker("Payment Cycle", selection: $paymentCycle) {
                        ForEach(PaymentCycle.allCases, id: \.self) { cycle in
                            Text(cycle.localizedName).tag(cycle)
                        }
                    }
                    
                    HStack {
                        Text("Security Deposit")
                        Spacer()
                        TextField("0", text: $depositAmount)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("¥")
                    }
                }
                
                Section {
                    Button("Create Contract") {
                        createContract()
                    }
                    .disabled(!isFormValid)
                }
            }
            .navigationTitle("Add Contract")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var isFormValid: Bool {
        return (selectedProperty != nil || property != nil) &&
               !tenantName.isEmpty &&
               !tenantPhone.isEmpty &&
               !rentAmount.isEmpty &&
               startDate < endDate
    }
    
    private func createContract() {
        guard let targetProperty = selectedProperty ?? property else {
            errorMessage = "Please select a property"
            showingError = true
            return
        }
        
        guard let rentAmountDecimal = Decimal(string: rentAmount) else {
            errorMessage = "Please enter a valid rent amount"
            showingError = true
            return
        }
        
        let depositAmountDecimal = Decimal(string: depositAmount) ?? 0
        
        // Create or find tenant
        let tenant = CoreDataService.shared.createTenant(
            name: tenantName.trimmingCharacters(in: .whitespacesAndNewlines),
            phone: tenantPhone.trimmingCharacters(in: .whitespacesAndNewlines),
            email: tenantEmail.isEmpty ? nil : tenantEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
        contractViewModel.addContract(
            property: targetProperty,
            tenant: tenant,
            startDate: startDate,
            endDate: endDate,
            rentAmount: rentAmountDecimal,
            paymentCycle: paymentCycle,
            depositAmount: depositAmountDecimal
        )
        
        dismiss()
    }
}

#Preview {
    AddContractView()
        .environmentObject(ContractViewModel())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
