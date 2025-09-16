import SwiftUI
import UIKit

struct ReportsTabView: View {
    @EnvironmentObject var propertyViewModel: PropertyViewModel
    @EnvironmentObject var paymentViewModel: PaymentViewModel
    @State private var selectedYear = Calendar.current.component(.year, from: Date())

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    yearSelectionSection
                    summarySection
                    exportOptionsSection
                    Spacer(minLength: 32)
                }
                .padding()
            }
            .navigationTitle("Reports")
        }
    }

    private var yearSelectionSection: some View {
        VStack(spacing: 12) {
            Text("Select Year")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            Picker("Year", selection: $selectedYear) {
                ForEach(2020...2030, id: \.self) { year in
                    Text("\(year)").tag(year)
                }
            }
            .pickerStyle(WheelPickerStyle())
            .frame(height: 100)
        }
    }

    private var summarySection: some View {
        VStack(spacing: 12) {
            Text("Year \(selectedYear) Summary")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 8) {
                HStack {
                    Text("Total Income:")
                        .font(.body)
                    Spacer()
                    Text("¥\(CoreDataService.shared.calculateYearlyIncome(year: selectedYear), specifier: "%.2f")")
                        .font(.body.bold())
                        .foregroundColor(.green)
                }

                HStack {
                    Text("Total Expenses:")
                        .font(.body)
                    Spacer()
                    Text("¥\(CoreDataService.shared.calculateYearlyExpenses(year: selectedYear), specifier: "%.2f")")
                        .font(.body.bold())
                        .foregroundColor(.red)
                }

                Divider()

                HStack {
                    Text("Net Income:")
                        .font(.body.bold())
                    Spacer()
                    let netIncome = CoreDataService.shared.calculateYearlyIncome(year: selectedYear) - CoreDataService.shared.calculateYearlyExpenses(year: selectedYear)
                    Text("¥\(netIncome, specifier: "%.2f")")
                        .font(.body.bold())
                        .foregroundColor(netIncome >= 0 ? .green : .red)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
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
        }
    }

    private func exportYearlyReport() {
        let pdf = PDFExportService.shared.generateYearlyReport(year: selectedYear)
        if let url = PDFExportService.shared.exportToTemporaryURL(pdf, filename: "Yearly_Report_\(selectedYear)") {
            presentShareSheet(url)
        }
    }
}

extension ReportsTabView {
    private func presentShareSheet(_ url: URL) {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else { return }
        let vc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        root.present(vc, animated: true)
    }
}

#Preview {
    ReportsTabView()
        .environmentObject(PropertyViewModel())
        .environmentObject(PaymentViewModel())
}