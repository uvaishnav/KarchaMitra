import SwiftUI
import SwiftData

struct QuickActionsView: View {
    @State private var selectedAction: QuickAction?
    @Query private var quickActions: [QuickAction]
    
    private let gridItems = [GridItem(.adaptive(minimum: 80))]

    var body: some View {
        VStack(alignment: .leading) {
            Text("Quick Actions")
                .font(.headline)
                .fontWeight(.medium)
                .padding([.horizontal, .top])

            LazyVGrid(columns: gridItems, spacing: 20) {
                ForEach(quickActions) { action in
                    Button(action: {
                        selectedAction = action
                    }) {
                        VStack {
                            Text(action.icon)
                                .font(.largeTitle)
                            Text(action.name)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .frame(width: 80, height: 80)
                        .background(.regularMaterial)
                        .cornerRadius(16)
                    }
                    .buttonStyle(ScaleOnPressButtonStyle())
                    .sensoryFeedback(.impact(weight: .light), trigger: selectedAction?.id)
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .sheet(item: $selectedAction) { action in
            AddExpenseView(amount: action.amount, reason: action.reason ?? "", category: action.category)
        }
    }
}

#Preview {
    QuickActionsView()
        .modelContainer(for: [QuickAction.self, Category.self], inMemory: true)
}
