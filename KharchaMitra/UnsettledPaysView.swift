import SwiftUI
import SwiftData

struct UnsettledPaysView: View {
    @Query var expenses: [Expense]
    
    @State private var activeSheet: SheetContent?
    
    // This struct helps in aggregating dues per person.
    struct AggregatedDebt: Identifiable, Hashable {
        let id = UUID()
        let name: String
        var amountOwed: Double
    }
    
    enum SheetContent: Identifiable {
        case settle(AggregatedDebt)
        case remind(AggregatedDebt)
        
        var id: String {
            switch self {
            case .settle(let debt): return "settle-\(debt.id)"
            case .remind(let debt): return "remind-\(debt.id)"
            }
        }
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
        Group {
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
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        Button {
                            activeSheet = .settle(debt)
                        } label: {
                            Label("Settle", systemImage: "indianrupeesign.circle.fill")
                        }
                        .tint(.green)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button {
                            activeSheet = .remind(debt)
                        } label: {
                            Label("Remind", systemImage: "bell.fill")
                        }
                        .tint(.blue)
                    }
                }
            }
        }
        .sheet(item: $activeSheet) { sheetContent in
            switch sheetContent {
            case .settle(let debt):
                AddPaymentView(participantName: debt.name)
            case .remind(let debt):
                let reminderText = "Reminder: You owe me \(debt.amountOwed.toCurrency()) for our shared expenses."
                ShareSheet(activityItems: [reminderText])
            }
        }
    }
}

#Preview {
    UnsettledPaysView()
        .modelContainer(for: [Expense.self, SharedParticipant.self], inMemory: true)
}