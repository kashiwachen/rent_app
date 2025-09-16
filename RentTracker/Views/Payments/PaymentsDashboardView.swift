import SwiftUI

struct PaymentsDashboardView: View {
    @EnvironmentObject var paymentViewModel: PaymentViewModel
    @EnvironmentObject var propertyViewModel: PropertyViewModel
    @State private var showingAddPayment = false
    @State private var showingAddExpense = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    // Summary Cards
                    summaryCardsSection
                    
                    // Overdue Payments Section
                    if !paymentViewModel.overduePayments.isEmpty {
                        overduePaymentsSection
                    }
                    
                    // Upcoming Payments Section
                    if !paymentViewModel.upcomingPayments.isEmpty {
                        upcomingPaymentsSection
                    }
                    
                    // Quick Actions
                    quickActionsSection
                }
                .padding()
            }
            .navigationTitle("Payment Dashboard")
            .refreshable {
                paymentViewModel.loadPayments()
                propertyViewModel.loadProperties()
            }
            .sheet(isPresented: $showingAddPayment) {
                AddPaymentView()
                    .environmentObject(paymentViewModel)
                    .environmentObject(propertyViewModel)
            }
            .sheet(isPresented: $showingAddExpense) {
                AddExpenseView()
                    .environmentObject(propertyViewModel)
            }
        }
    }
    
    private var summaryCardsSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            SummaryCard(
                title: "Overdue",
                value: paymentViewModel.formatAmount(paymentViewModel.getTotalOverdueAmount()),
                count: paymentViewModel.getOverduePaymentsCount(),
                color: .red,
                icon: "exclamationmark.triangle.fill"
            )
            
            SummaryCard(
                title: "Upcoming (7 days)",
                value: "",
                count: paymentViewModel.getUpcomingPaymentsCount(),
                color: .orange,
                icon: "clock.fill"
            )
            
            SummaryCard(
                title: "Total Income",
                value: paymentViewModel.formatAmount(propertyViewModel.getTotalIncome()),
                count: nil,
                color: .green,
                icon: "arrow.up.circle.fill"
            )
            
            SummaryCard(
                title: "Net Income",
                value: paymentViewModel.formatAmount(propertyViewModel.getNetIncome()),
                count: nil,
                color: .blue,
                icon: "chart.line.uptrend.xyaxis"
            )
        }
    }
    
    private var overduePaymentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                Text("Overdue Payments")
                    .font(.headline)
                    .foregroundColor(.red)
                Spacer()
            }
            
            LazyVStack(spacing: 8) {
                ForEach(paymentViewModel.overduePayments, id: \.id) { payment in
                    PaymentRowView(paymentSchedule: payment, isOverdue: true) {
                        paymentViewModel.markPaymentAsPaid(payment)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var upcomingPaymentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.orange)
                Text("Upcoming Payments")
                    .font(.headline)
                Spacer()
            }
            
            LazyVStack(spacing: 8) {
                ForEach(paymentViewModel.upcomingPayments, id: \.id) { payment in
                    PaymentRowView(paymentSchedule: payment, isOverdue: false) {
                        paymentViewModel.markPaymentAsPaid(payment)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var quickActionsSection: some View {
        VStack(spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 12) {
                Button(action: { showingAddPayment = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Payment")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                
                Button(action: { showingAddExpense = true }) {
                    HStack {
                        Image(systemName: "minus.circle.fill")
                        Text("Add Expense")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct SummaryCard: View {
    let title: String
    let value: String
    let count: Int?
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
            
            if !value.isEmpty {
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
            }
            
            if let count = count {
                Text("\(count) items")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct PaymentRowView: View {
    let paymentSchedule: PaymentSchedule
    let isOverdue: Bool
    let onMarkPaid: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(paymentSchedule.contract?.property?.name ?? "Unknown Property")
                    .font(.headline)
                
                Text(paymentSchedule.contract?.tenant?.name ?? "Unknown Tenant")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text(PaymentViewModel().formatAmount(paymentSchedule.amount))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text("• Due: \(PaymentViewModel().formatDate(paymentSchedule.dueDate))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if isOverdue {
                    Text("\(paymentSchedule.daysOverdue) days overdue")
                        .font(.caption)
                        .foregroundColor(.red)
                        .fontWeight(.medium)
                }
            }
            
            Spacer()
            
            Button("Mark Paid") {
                onMarkPaid()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    PaymentsDashboardView()
        .environmentObject(PaymentViewModel())
        .environmentObject(PropertyViewModel())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
