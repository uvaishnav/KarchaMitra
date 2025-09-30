import SwiftUI
import SwiftData

struct UnsettledPaysView: View {
    @Query var expenses: [Expense]
    
    // This struct helps in aggregating dues per person.
    struct AggregatedDebt: Identifiable {
        let id = UUID()
        let name: String
        var amountOwed: Double
    }
    
    private var aggregatedDebts: [AggregatedDebt] {
        let sharedExpenses = expenses.filter { $0.isShared }
        let allParticipants = sharedExpenses.flatMap { $0.sharedParticipants }
        
        let unsettledParticipants = allParticipants.filter { $0.amountRemaining > 0 }
        
        // Group by name and sum the remaining amounts
        let dictionary = Dictionary(grouping: unsettledParticipants, by: { $0.name })
            .mapValues { participants in
                participants.reduce(0) { $0 + $1.amountRemaining }
            }
        
        return dictionary.map {
            AggregatedDebt(name: $0.key, amountOwed: $0.value)
        }.sorted(by: { $0.name < $1.name })
    }
    
    var body: some View {
        if aggregatedDebts.isEmpty {
            Text("No unsettled expenses yet.")
                .foregroundColor(.secondary)
        } else {
            ForEach(aggregatedDebts) { debt in
                NavigationLink(destination: DebtDetailView(participantName: debt.name)) {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text(debt.name)
                        Spacer()
                        Text(debt.amountOwed.toCurrency())
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

#Preview {
    UnsettledPaysView()
        .modelContainer(for: [Expense.self, SharedParticipant.self], inMemory: true)
}