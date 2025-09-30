import SwiftUI
import SwiftData

struct DebtDetailView: View {
    let participantName: String
    
    @Query var expenses: [Expense]
    @Query var settlements: [Settlement]
    
    @State private var showingAddPayment = false
    
    private var debts: [Expense] {
        expenses.filter {
            $0.isShared && $0.sharedParticipants.contains { $0.name == participantName && $0.amountRemaining > 0 }
        }
    }
    
    private var payments: [Settlement] {
        settlements.filter { $0.participantName == participantName }
    }
    
    private var totalOwed: Double {
        debts.flatMap { $0.sharedParticipants }
            .filter { $0.name == participantName }
            .reduce(0) { $0 + $1.amountRemaining }
    }

    var body: some View {
        VStack {
            List {
                Section("Owed Expenses") {
                    ForEach(debts) { expense in
                        HStack {
                            Text(expense.reason ?? "Uncategorized")
                            Spacer()
                            Text(expense.sharedParticipants.first { $0.name == participantName }?.amountRemaining.toCurrency() ?? "")
                        }
                    }
                }
                
                Section("Payments Made") {
                    ForEach(payments) { payment in
                        HStack {
                            Text(payment.date.formatted(date: .abbreviated, time: .shortened))
                            Spacer()
                            Text(payment.amount.toCurrency())
                        }
                    }
                }
            }
        }
        .navigationTitle(participantName)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Add Payment") {
                    showingAddPayment.toggle()
                }
            }
        }
        .sheet(isPresented: $showingAddPayment) {
            AddPaymentView(participantName: participantName)
        }
    }
}

#Preview {
    DebtDetailView(participantName: "John Doe")
}