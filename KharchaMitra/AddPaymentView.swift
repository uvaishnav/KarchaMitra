
import SwiftUI
import SwiftData

struct AddPaymentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let participantName: String
    
    @State private var amount: Double?
    
    @Query private var expenses: [Expense]

    private var isFormValid: Bool {
        amount != nil && amount ?? 0 > 0
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Payment from \(participantName)")) {
                    TextField("Amount Received", value: $amount, format: .currency(code: "INR"))
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("Record Payment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save", action: savePayment)
                        .disabled(!isFormValid)
                }
            }
        }
    }

    private func savePayment() {
        guard var paymentAmount = amount, paymentAmount > 0 else { return }

        // Create a settlement record for the history
        let newSettlement = Settlement(
            amount: paymentAmount,
            date: Date(),
            participantName: participantName
        )
        modelContext.insert(newSettlement)

        // 1. Find all shared expenses involving this person where they still owe money.
        let sharedExpenses = expenses.filter { $0.isShared }
        
        var unsettledDebts: [(participant: SharedParticipant, expenseDate: Date)] = []

        for expense in sharedExpenses {
            for participant in expense.sharedParticipants {
                if participant.name == participantName && participant.amountRemaining > 0 {
                    unsettledDebts.append((participant, expense.date))
                }
            }
        }

        // 2. Sort the debts from oldest to newest (FIFO).
        unsettledDebts.sort { $0.expenseDate < $1.expenseDate }

        // 3. Apply the payment across the debts.
        for debt in unsettledDebts {
            if paymentAmount <= 0 { break }

            let participant = debt.participant
            let amountToSettle = min(paymentAmount, participant.amountRemaining)
            
            participant.amountPaid += amountToSettle
            paymentAmount -= amountToSettle
        }
        
        // SwiftData automatically saves the changes to the model context.
        dismiss()
    }
}

#Preview {
    AddPaymentView(participantName: "John Doe")
        .modelContainer(for: [Expense.self, SharedParticipant.self], inMemory: true)
}
