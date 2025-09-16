import SwiftUI

struct ReportsTabView: View {
    @EnvironmentObject var propertyViewModel: PropertyViewModel
    @EnvironmentObject var paymentViewModel: PaymentViewModel
    @State private var selectedYear = Calendar.current.component(.year, from: Date())
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Year Selector
                    yearSelectorSection
                    
                    // Financial Overview
                    financialOverviewSection
                    
                    // Property Performance
                    propertyPerformanceSection
                    
                    // Vacancy Rate
                    vacancyRateSection
                    
                    // Export Options
                    exportOptionsSection
                }
                .padding()
            }
            .navigationTitle("Reports")
        }
    }
    
    private var yearSelectorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Report Year")
                .font(.headline)
            
            Picker("Year", selection: $selectedYear) {
                ForEach(2020...2030, id: \.self) { year in
                    Text(String(year)).tag(year)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var financialOverviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Financial Overview (\(selectedYear))")
                .font(.headline)
            
            let yearlyIncome = CoreDataService.shared.calculateYearlyIncome(year: selectedYear)
            let yearlyExpenses = CoreDataService.shared.calculateYearlyExpenses(year: selectedYear)
            let netIncome = yearlyIncome - yearlyExpenses
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                FinancialSummaryCard(
                    title: "Total Income",
                    amount: yearlyIncome,
                    color: .green,
                    icon: "arrow.up.circle.fill"
                )
                
                FinancialSummaryCard(
                    title: "Total Expenses",
                    amount: yearlyExpenses,
                    color: .red,
                    icon: "arrow.down.circle.fill"
                )
            }
            
            FinancialSummaryCard(
                title: "Net Income",
                amount: netIncome,
                color: netIncome >= 0 ? .green : .red,
                icon: "chart.line.uptrend.xyaxis"
            )
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var propertyPerformanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Property Performance")
                .font(.headline)
            
            ForEach(propertyViewModel.properties, id: \.id) { property in
                PropertyPerformanceRow(property: property)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var vacancyRateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Occupancy Statistics")
                .font(.headline)
            
            let vacancyRate = propertyViewModel.getVacancyRate()
            let occupancyRate = 100 - vacancyRate
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Occupancy Rate")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("\(String(format: "%.1f", occupancyRate))%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Vacancy Rate")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("\(String(format: "%.1f", vacancyRate))%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }
            }
            
            // Simple progress bar
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.green)
                        .frame(width: geometry.size.width * CGFloat(occupancyRate / 100))
                    
                    Rectangle()
                        .fill(Color.orange)
                        .frame(width: geometry.size.width * CGFloat(vacancyRate / 100))
                }
            }
            .frame(height: 8)
            .cornerRadius(4)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var exportOptionsSection: some View {
        VStack(spacing: 12) {
            Text("Export Options")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Button(action: exportYearlyReport) {
                HStack {
                    Image(systemName: "doc.text")
                    Text("Export Yearly Report (PDF)")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            
            Button(action: exportPropertyReport) {
                HStack {
                    Image(systemName: "house.and.flag")
                    Text("Export Property Report (PDF)")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func exportYearlyReport() {
        // TODO: Implement PDF export functionality
        print("Export yearly report for \(selectedYear)")
    }
    
    private func exportPropertyReport() {
        // TODO: Implement PDF export functionality
        print("Export property report")
    }
}

struct FinancialSummaryCard: View {
    let title: String
    let amount: Decimal
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                Spacer()
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(formatAmount(amount))
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
    
    private func formatAmount(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "¥"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: amount as NSDecimalNumber) ?? "¥0"
    }
}

struct PropertyPerformanceRow: View {
    let property: Property
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(property.name ?? "Unknown Property")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack {
                    if property.isVacant {
                        Label("Vacant", systemImage: "house")
                            .font(.caption)
                            .foregroundColor(.orange)
                    } else {
                        Label(property.currentTenant?.name ?? "Unknown", systemImage: "person.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(formatAmount(property.totalIncome))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.green)
                
                Text("Net: \(formatAmount(property.netIncome))")
                    .font(.caption)
                    .foregroundColor(property.netIncome >= 0 ? .green : .red)
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
}

#Preview {
    ReportsTabView()
        .environmentObject(PropertyViewModel())
        .environmentObject(PaymentViewModel())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
