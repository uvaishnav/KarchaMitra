import SwiftUI
import SwiftData

struct UnsettledPaysView: View {
    @Query var expenses: [Expense]
    
    @State private var activeSheet: SheetContent?
    @State private var animateCards = false
    
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
                // Modern Empty State
                VStack(spacing: AppSpacing.md) {
                    ZStack {
                        Circle()
                            .fill(Color.primaryGradient)
                            .frame(width: 80, height: 80)
                            .opacity(0.2)
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(Color.primaryGradient)
                    }
                    
                    Text("All Settled Up! 🎉")
                        .font(.headline)
                        .foregroundColor(.textPrimary)
                    
                    Text("You have no pending shared expenses")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.xl)
            } else {
                ForEach(Array(aggregatedDebts.enumerated()), id: \.element.id) { index, debt in
                    NavigationLink(destination: DebtDetailView(participantName: debt.name)) {
                        UnsettledDebtCard(debt: debt)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        Button {
                            activeSheet = .settle(debt)
                        } label: {
                            Label("Settle", systemImage: "checkmark.circle.fill")
                        }
                        .tint(.successGreen)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button {
                            activeSheet = .remind(debt)
                        } label: {
                            Label("Remind", systemImage: "bell.fill")
                        }
                        .tint(.infoBlue)
                    }
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    .listRowSeparator(.hidden)
                    .scaleEffect(animateCards ? 1.0 : 0.9)
                    .opacity(animateCards ? 1.0 : 0.0)
                    .animation(
                        .spring(response: 0.5, dampingFraction: 0.7)
                            .delay(Double(index) * 0.1),
                        value: animateCards
                    )
                }
            }
        }
        .onAppear {
            withAnimation {
                animateCards = true
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

// MARK: - Unsettled Debt Card Component
struct UnsettledDebtCard: View {
    let debt: UnsettledPaysView.AggregatedDebt
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Profile icon with gradient
            ZStack {
                Circle()
                    .fill(Color.primaryGradient)
                    .frame(width: 50, height: 50)
                    .glowShadow(color: Color.brandMagenta)
                
                Image(systemName: "person.fill")
                    .font(.title3)
                    .foregroundColor(.white)
            }
            
            // Debt details
            VStack(alignment: .leading, spacing: 4) {
                Text(debt.name)
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.caption2)
                    Text("Pending settlement")
                        .font(.caption)
                }
                .foregroundColor(.textSecondary)
            }
            
            Spacer()
            
            // Amount with arrow
            HStack(spacing: AppSpacing.xs) {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(debt.amountOwed.toCurrency())
                        .font(.system(.title3, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.warningOrange)
                        .monospacedDigit()
                    
                    Text("You'll get")
                        .font(.caption2)
                        .foregroundColor(.textSecondary)
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.textTertiary)
            }
        }
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.large)
                .fill(Color.cardBackground)
                .softShadow()
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppCornerRadius.large)
                .stroke(Color.divider.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    UnsettledPaysView()
        .modelContainer(for: [Expense.self, SharedParticipant.self], inMemory: true)
}
