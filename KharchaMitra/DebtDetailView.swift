import SwiftUI
import SwiftData

struct DebtDetailView: View {
    let participantName: String
    
    @Query var expenses: [Expense]
    @Query var settlements: [Settlement]
    
    @State private var showingAddPayment = false
    @State private var cardsAppear = false
    
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
    
    private var totalPaid: Double {
        payments.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: AppSpacing.lg) {
                // Summary Header
                DebtSummaryCard(
                    participantName: participantName,
                    totalOwed: totalOwed,
                    totalPaid: totalPaid
                )
                .padding(.top, AppSpacing.sm)
                .scaleEffect(cardsAppear ? 1.0 : 0.9)
                .opacity(cardsAppear ? 1.0 : 0.0)
                
                // Owed Expenses Section
                if !debts.isEmpty {
                    ModernDebtSection(
                        title: "Pending Expenses",
                        icon: "clock.arrow.circlepath",
                        iconColor: .warningOrange
                    ) {
                        VStack(spacing: AppSpacing.sm) {
                            ForEach(debts) { expense in
                                DebtExpenseCard(expense: expense, participantName: participantName)
                            }
                        }
                    }
                    .scaleEffect(cardsAppear ? 1.0 : 0.95)
                    .opacity(cardsAppear ? 1.0 : 0.0)
                }
                
                // Payments Section
                if !payments.isEmpty {
                    ModernDebtSection(
                        title: "Payment History",
                        icon: "checkmark.circle.fill",
                        iconColor: .successGreen
                    ) {
                        VStack(spacing: AppSpacing.sm) {
                            ForEach(payments) { payment in
                                PaymentHistoryCard(payment: payment)
                            }
                        }
                    }
                    .scaleEffect(cardsAppear ? 1.0 : 0.95)
                    .opacity(cardsAppear ? 1.0 : 0.0)
                }
                
                // Empty State
                if debts.isEmpty && payments.isEmpty {
                    EmptyDebtView()
                        .padding(.top, AppSpacing.xxl)
                }
                
                Spacer()
                    .frame(height: AppSpacing.xl)
            }
            .padding(.horizontal, AppSpacing.md)
        }
        .background(
            LinearGradient(
                colors: [
                    Color.secondaryBackground,
                    Color.tertiaryBackground.opacity(0.5)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .navigationTitle(participantName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddPayment.toggle() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text("Payment")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(Color.primaryGradient)
                }
                .disabled(totalOwed <= 0)
            }
        }
        .sheet(isPresented: $showingAddPayment) {
            AddPaymentView(participantName: participantName)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
                cardsAppear = true
            }
        }
    }
}

// MARK: - Debt Summary Card
struct DebtSummaryCard: View {
    let participantName: String
    let totalOwed: Double
    let totalPaid: Double
    
    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            // Profile Section
            VStack(spacing: AppSpacing.sm) {
                ZStack {
                    Circle()
                        .stroke(Color.primaryGradient, lineWidth: 3)
                        .frame(width: 80, height: 80)
                        .glowShadow(color: Color.brandMagenta)
                    
                    ZStack {
                        Circle()
                            .fill(Color.cardBackground)
                            .frame(width: 74, height: 74)
                        
                        Image(systemName: "person.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(Color.primaryGradient)
                    }
                }
                
                Text(participantName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
            }
            
            Divider()
            
            // Financial Summary
            HStack(spacing: 0) {
                // Amount Owed
                VStack(spacing: AppSpacing.xs) {
                    Text("Amount Owed")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                    
                    Text(totalOwed.toCurrency())
                        .font(.system(.title2, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(totalOwed > 0 ? .warningOrange : .successGreen)
                        .monospacedDigit()
                    
                    if totalOwed > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.caption2)
                            Text("Pending")
                                .font(.caption2)
                        }
                        .foregroundColor(.warningOrange)
                        .padding(.horizontal, AppSpacing.sm)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.warningOrange.opacity(0.15))
                        )
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption2)
                            Text("All settled")
                                .font(.caption2)
                        }
                        .foregroundColor(.successGreen)
                        .padding(.horizontal, AppSpacing.sm)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.successGreen.opacity(0.15))
                        )
                    }
                }
                .frame(maxWidth: .infinity)
                
                Capsule()
                    .fill(Color.divider)
                    .frame(width: 1, height: 60)
                
                // Total Paid
                VStack(spacing: AppSpacing.xs) {
                    Text("Total Paid")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                    
                    Text(totalPaid.toCurrency())
                        .font(.system(.title2, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.successGreen)
                        .monospacedDigit()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.caption2)
                        Text("Received")
                            .font(.caption2)
                    }
                    .foregroundColor(.successGreen)
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.successGreen.opacity(0.15))
                    )
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(AppSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.xLarge)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: AppCornerRadius.xLarge)
                        .stroke(Color.divider.opacity(0.3), lineWidth: 1)
                )
                .elevatedShadow()
        )
    }
}

// MARK: - Modern Debt Section
struct ModernDebtSection<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    let content: Content
    
    init(
        title: String,
        icon: String,
        iconColor: Color,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.iconColor = iconColor
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(iconColor)
                
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
            }
            
            content
        }
    }
}

// MARK: - Debt Expense Card
struct DebtExpenseCard: View {
    let expense: Expense
    let participantName: String
    
    private var participantDebt: Double {
        expense.sharedParticipants
            .first { $0.name == participantName }?
            .amountRemaining ?? 0
    }
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Category Icon
            ZStack {
                RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                    .fill(Color(hex: expense.category?.colorHex ?? "#E91E63").opacity(0.15))
                    .frame(width: 50, height: 50)
                
                Text(expense.category?.iconName ?? "📦")
                    .font(.title2)
            }
            
            // Expense Details
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.reason ?? "Shared Expense")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
                
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption2)
                    Text(expense.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                }
                .foregroundColor(.textSecondary)
                
                // Total vs Owed
                HStack(spacing: AppSpacing.xs) {
                    Text("Total:")
                        .font(.caption2)
                    Text(expense.amount.toCurrency())
                        .font(.caption2)
                        .monospacedDigit()
                }
                .foregroundColor(.textTertiary)
            }
            
            Spacer()
            
            // Amount Owed
            VStack(alignment: .trailing, spacing: 2) {
                Text(participantDebt.toCurrency())
                    .font(.system(.headline, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.warningOrange)
                    .monospacedDigit()
                
                Text("Pending")
                    .font(.caption2)
                    .foregroundColor(.textSecondary)
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
                .stroke(Color.warningOrange.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Payment History Card
struct PaymentHistoryCard: View {
    let payment: Settlement
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                    .fill(Color.successGreen.opacity(0.15))
                    .frame(width: 50, height: 50)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.successGreen)
            }
            
            // Payment Details
            VStack(alignment: .leading, spacing: 4) {
                Text("Payment Received")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
                
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption2)
                    Text(payment.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                }
                .foregroundColor(.textSecondary)
            }
            
            Spacer()
            
            // Amount
            Text(payment.amount.toCurrency())
                .font(.system(.headline, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(.successGreen)
                .monospacedDigit()
        }
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.large)
                .fill(Color.cardBackground)
                .softShadow()
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppCornerRadius.large)
                .stroke(Color.successGreen.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Empty Debt View
struct EmptyDebtView: View {
    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            ZStack {
                Circle()
                    .fill(Color.successGreen.opacity(0.2))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.successGreen)
            }
            
            VStack(spacing: AppSpacing.sm) {
                Text("All Settled!")
                    .font(.title3.bold())
                    .foregroundColor(.textPrimary)
                
                Text("No pending expenses or payments")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.xxl)
    }
}

#Preview {
    NavigationView {
        DebtDetailView(participantName: "John Doe")
            .modelContainer(for: [Expense.self, Settlement.self], inMemory: true)
    }
}
