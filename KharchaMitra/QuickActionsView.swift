import SwiftUI
import SwiftData

struct QuickActionsView: View {
    @State private var selectedAction: QuickAction?
        @State private var pressedActionId: PersistentIdentifier?
    @Query private var quickActions: [QuickAction]
    
    private let gridItems = [GridItem(.adaptive(minimum: 85), spacing: AppSpacing.md)]

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Section Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Quick Actions")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)
                    
                    Text("Tap to add frequent expenses")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                // Optional: Add action count badge
                if !quickActions.isEmpty {
                    Text("\(quickActions.count)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                        .background(
                            Circle()
                                .fill(Color.primaryGradient)
                        )
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.top, AppSpacing.sm)

            // Grid of Quick Action Buttons
            LazyVGrid(columns: gridItems, spacing: AppSpacing.md) {
                ForEach(quickActions) { action in
                    QuickActionButton(
                        action: action,
                        isPressed: pressedActionId == action.id
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            pressedActionId = action.id
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            pressedActionId = nil
                            selectedAction = action
                        }
                    }
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.bottom, AppSpacing.sm)
        }
        .sheet(item: $selectedAction) { action in
            AddExpenseView(amount: action.amount, reason: action.reason ?? "", category: action.category)
        }
    }
}

// MARK: - Quick Action Button Component
struct QuickActionButton: View {
    let action: QuickAction
    let isPressed: Bool
    let onTap: () -> Void
    
    @State private var isAppearing = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: AppSpacing.sm) {
                // Icon with gradient background
                ZStack {
                    Circle()
                        .fill(Color.primaryGradient)
                        .frame(width: 46, height: 46)
                        .glowShadow(color: Color.brandMagenta)
                    
                    Text(action.icon)
                        .font(.system(size: 26))
                }
                
                // Action name
                Text(action.name)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.8)
            }
            .frame(width: 85, height: 95)
            .background(
                RoundedRectangle(cornerRadius: AppCornerRadius.large)
                    .fill(Color.cardBackground)
                    .softShadow()
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.large)
                    .stroke(Color.divider.opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.92 : 1.0)
            .scaleEffect(isAppearing ? 1.0 : 0.8)
            .opacity(isAppearing ? 1.0 : 0.0)
        }
        .buttonStyle(PlainButtonStyle())
        .sensoryFeedback(.impact(weight: .light), trigger: isPressed)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double.random(in: 0...0.3))) {
                isAppearing = true
            }
        }
    }
}



#Preview {
    QuickActionsView()
        .modelContainer(for: [QuickAction.self, Category.self], inMemory: true)
}
