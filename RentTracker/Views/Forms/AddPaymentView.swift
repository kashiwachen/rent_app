import SwiftUI

struct AddPaymentView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var paymentViewModel: PaymentViewModel
    @EnvironmentObject var propertyViewModel: PropertyViewModel
    
    @State private var selectedContract: Contract?
    @State private var amount = ""
    @State private var paymentType = PaymentType.rent
    @State private var paymentMethod = PaymentMethod.bankTransfer
    @State private var paidDate = Date()
    @State private var dueDate = Date()
    @State private var isPartial = false
    @State private var notes = ""
    
    @State private var showingError = false
    @State private var errorMessage = ""
    
    private var activeContracts: [Contract] {
        return CoreDataService.shared.fetchActiveContracts()
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Contract") {
                    Picker("Select Contract", selection: $selectedContract) {
                        Text("Select a contract").tag(nil as Contract?)
                        ForEach(activeContracts, id: \.id) { contract in
                            HStack {
                                Text(contract.property?.name ?? "Unknown Property")
                                Text("•")
                                Text(contract.tenant?.name ?? "Unknown Tenant")
                            }
                            .tag(contract as Contract?)
                        }
                    }
                }
                
                Section("Payment Details") {
                    HStack {
                        Text("Amount")
                        Spacer()
                        TextField("0", text: $amount)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("¥")
                    }
                    
                    Picker("Payment Type", selection: $paymentType) {
                        ForEach(PaymentType.allCases, id: \.self) { type in
                            Label(type.localizedName, systemImage: type.isIncome ? "arrow.up.circle" : "arrow.down.circle")
                                .tag(type)
                        }
                    }
                    
                    Picker("Payment Method", selection: $paymentMethod) {
                        ForEach(PaymentMethod.allCases, id: \.self) { method in
                            Label(method.localizedName, systemImage: method.iconName)
                                .tag(method)
                        }
                    }
                    
                    DatePicker("Paid Date", selection: $paidDate, displayedComponents: .date)
                    
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                    
                    Toggle("Partial Payment", isOn: $isPartial)
                }
                
                Section("Notes") {
                    TextField("Additional notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section {
                    Button("Add Payment") {
                        addPayment()
                    }
                    .disabled(!isFormValid)
                }
            }
            .navigationTitle("Add Payment")
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
        return selectedContract != nil && !amount.isEmpty
    }
    
    private func addPayment() {
        guard let contract = selectedContract else {
            errorMessage = "Please select a contract"
            showingError = true
            return
        }
        
        guard let amountDecimal = Decimal(string: amount) else {
            errorMessage = "Please enter a valid amount"
            showingError = true
            return
        }
        
        paymentViewModel.addPayment(
            contract: contract,
            amount: amountDecimal,
            dueDate: dueDate,
            paymentType: paymentType,
            paymentMethod: paymentMethod,
            paidDate: paidDate,
            isPartial: isPartial,
            notes: notes.isEmpty ? nil : notes
        )
        
        dismiss()
    }
}

#Preview {
    AddPaymentView()
        .environmentObject(PaymentViewModel())
        .environmentObject(PropertyViewModel())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
