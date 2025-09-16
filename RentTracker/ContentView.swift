import SwiftUI

struct ContentView: View {
    @StateObject private var propertyViewModel = PropertyViewModel()
    @StateObject private var contractViewModel = ContractViewModel()
    @StateObject private var paymentViewModel = PaymentViewModel()
    
    var body: some View {
        TabView {
            PaymentsDashboardView()
                .environmentObject(paymentViewModel)
                .environmentObject(propertyViewModel)
                .tabItem {
                    Image(systemName: "creditcard")
                    Text("Payments")
                }
            
            PropertiesListView()
                .environmentObject(propertyViewModel)
                .environmentObject(contractViewModel)
                .tabItem {
                    Image(systemName: "house")
                    Text("Properties")
                }
            
            ContractsListView()
                .environmentObject(contractViewModel)
                .environmentObject(propertyViewModel)
                .tabItem {
                    Image(systemName: "doc.text")
                    Text("Contracts")
                }
            
            ReportsTabView()
                .environmentObject(propertyViewModel)
                .environmentObject(paymentViewModel)
                .tabItem {
                    Image(systemName: "chart.bar")
                    Text("Reports")
                }
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
        }
        .accentColor(.blue)
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
