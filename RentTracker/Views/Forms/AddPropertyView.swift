import SwiftUI

struct AddPropertyView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var propertyViewModel: PropertyViewModel
    
    @State private var name = ""
    @State private var address = ""
    @State private var propertyType = PropertyType.residential
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Property Information") {
                    TextField("Property Name", text: $name)
                        .textInputAutocapitalization(.words)
                    
                    TextField("Address", text: $address)
                        .textInputAutocapitalization(.words)
                    
                    Picker("Property Type", selection: $propertyType) {
                        ForEach(PropertyType.allCases, id: \.self) { type in
                            Text(type.localizedName).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section {
                    Button("Add Property") {
                        addProperty()
                    }
                    .disabled(name.isEmpty || address.isEmpty)
                }
            }
            .navigationTitle("Add Property")
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
    
    private func addProperty() {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Property name is required"
            showingError = true
            return
        }
        
        guard !address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Address is required"
            showingError = true
            return
        }
        
        propertyViewModel.addProperty(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            address: address.trimmingCharacters(in: .whitespacesAndNewlines),
            type: propertyType
        )
        
        dismiss()
    }
}

#Preview {
    AddPropertyView()
        .environmentObject(PropertyViewModel())
}
