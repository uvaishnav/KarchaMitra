
import SwiftUI
import SwiftData

// A helper struct to link a participant's debt to the specific expense it came from.
struct ParticipantExpense: Identifiable {
    let id: UUID
    let participantId: UUID
    let expenseReason: String
    let expenseDate: Date
    let amountRemaining: Double
}

struct DebtDetailView: View {
    let participantName: String
    
    @Query private var expenses: [Expense]
    @State private var showingAddPaymentSheet = false
    
    private var debts: [ParticipantExpense] {
        // Get all shared expenses involving this person
        let sharedExpenses = expenses.filter { $0.isShared }
        
        var participantExpenses: [ParticipantExpense] = []
        
        for expense in sharedExpenses {
            for participant in expense.sharedParticipants {
                if participant.name == participantName && participant.amountRemaining > 0 {
                    let detail = ParticipantExpense(
                        id: expense.id,
                        participantId: participant.id,
                        expenseReason: expense.reason?.isEmpty == false ? expense.reason! : (expense.category?.name ?? "Uncategorized"),
                        expenseDate: expense.date,
                        amountRemaining: participant.amountRemaining
                    )
                    participantExpenses.append(detail)
                }
            }
        }
        
        return participantExpenses.sorted(by: { $0.expenseDate < $1.expenseDate })
    }
    
    private var totalDebt: Double {
        debts.reduce(0) { $0 + $1.amountRemaining }
    }
    
    var body: some View {
        VStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total Owed")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(totalDebt.toCurrency())
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                    }
                    .padding(.vertical)
                }
                
                Section(header: Text("Itemized Debts")) {
                    if debts.isEmpty {
                        Text("All debts are settled!")
                    } else {
                        ForEach(debts) { debt in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(debt.expenseReason)
                                        .font(.headline)
                                    Text(debt.expenseDate.formatted(date: .long, time: .omitted))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Text(debt.amountRemaining.toCurrency())
                                    .fontWeight(.medium)
                            }
                        }
                    }
                }
            }
            
            Button("Record a Payment", systemImage: "plus.circle.fill") {
                showingAddPaymentSheet.toggle()
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
        .sheet(isPresented: $showingAddPaymentSheet) {
            AddPaymentView(participantName: participantName)
        }
        .navigationTitle(participantName)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    // This preview requires some setup to be useful
    NavigationView {
        DebtDetailView(participantName: "John Doe")
            .modelContainer(for: [Expense.self, SharedParticipant.self, Category.self], inMemory: true)
    }
}
