import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showingAddExpenseSheet = false
    @State private var headerOpacity: Double = 0
    @State private var cardsAppear = false

    @Query var expenses: [Expense]
    @Query var settings: [UserSettings]
    @Query var recurringTemplates: [RecurringExpenseTemplate]

    private var userSettings: UserSettings {
        settings.first ?? UserSettings()
    }

    private var netMonthlyCashFlow: Double {
        let monthlyExpenses = expenses.filter { Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .month) }
        let grossSpent = monthlyExpenses.reduce(0) { $0 + $1.amount }
        let totalRecovered = monthlyExpenses
            .flatMap { $0.sharedParticipants }
            .reduce(0) { $0 + $1.amountPaid }
        return grossSpent - totalRecovered
    }

    private var monthlySpendingAgainstLimit: Double {
        let limitedExpenses = expenses.filter {
            Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .month) &&
            $0.category?.type != .UTR
        }
        let grossSpent = limitedExpenses.reduce(0) { $0 + $1.amount }
        let totalRecovered = limitedExpenses
            .flatMap { $0.sharedParticipants }
            .reduce(0) { $0 + $1.amountPaid }
        return grossSpent - totalRecovered
    }

    private var limitLeft: Double {
        userSettings.expenseLimit - monthlySpendingAgainstLimit
    }
    
    private var lastMonthRecurringTotal: Double {
        let calendar = Calendar.current
        guard let lastMonth = calendar.date(byAdding: .month, value: -1, to: Date()) else { return 0 }
        guard let startOfLastMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: lastMonth)) else { return 0 }
        guard let startOfThisMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: Date())) else { return 0 }

        let lastMonthExpenses = expenses.filter { expense in
            return expense.date >= startOfLastMonth && expense.date < startOfThisMonth && expense.recurringTemplate != nil
        }
        return lastMonthExpenses.reduce(0) { $0 + $1.amount }
    }

    private var thisMonthRecurringSpent: Double {
        let calendar = Calendar.current
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: Date())) else { return 0 }

        let thisMonthExpenses = expenses.filter { expense in
            return expense.date >= startOfMonth && expense.recurringTemplate != nil
        }
        return thisMonthExpenses.reduce(0) { $0 + $1.amount }
    }

    private var safeLimit: Double {
        let estimatedRecurring = lastMonthRecurringTotal - thisMonthRecurringSpent
        if lastMonthRecurringTotal > 0 && estimatedRecurring > 0 {
            return limitLeft - estimatedRecurring
        }
        return limitLeft
    }

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottomTrailing) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: AppSpacing.lg) {
                        // Modern Header
                        ModernHeaderView()
                            .padding(.horizontal, AppSpacing.md)
                            .padding(.top, AppSpacing.sm)
                            .opacity(headerOpacity)
                        
                        // Budget Progress (Hero Section)
                        BudgetProgressView(
                            limit: userSettings.expenseLimit,
                            spending: monthlySpendingAgainstLimit,
                            safeLimit: safeLimit,
                            limitLeft: limitLeft
                        )
                        .scaleEffect(cardsAppear ? 1.0 : 0.95)
                        .opacity(cardsAppear ? 1.0 : 0.0)
                        
                        // Spending Summary Card
                        SpendingSummaryCard(
                            amountSpent: netMonthlyCashFlow,
                            savingBuffer: userSettings.savingBuffer
                        )
                        .padding(.horizontal, AppSpacing.md)
                        .scaleEffect(cardsAppear ? 1.0 : 0.95)
                        .opacity(cardsAppear ? 1.0 : 0.0)
                        
                        // Quick Actions
                        QuickActionsView()
                            .scaleEffect(cardsAppear ? 1.0 : 0.95)
                            .opacity(cardsAppear ? 1.0 : 0.0)
                        
                        // Recurring Expenses Section
                        ModernSectionView(
                            title: "Recurring Expenses",
                            icon: "arrow.clockwise.circle.fill",
                            iconColor: .infoBlue
                        ) {
                            RecurringExpensesView(templates: recurringTemplates, expenses: expenses)
                        }
                        .scaleEffect(cardsAppear ? 1.0 : 0.95)
                        .opacity(cardsAppear ? 1.0 : 0.0)
                        
                        // Unsettled Shared Expenses Section
                        ModernSectionView(
                            title: "Unsettled Expenses",
                            icon: "person.2.circle.fill",
                            iconColor: .warningOrange
                        ) {
                            UnsettledPaysView()
                        }
                        .scaleEffect(cardsAppear ? 1.0 : 0.95)
                        .opacity(cardsAppear ? 1.0 : 0.0)
                        
                        // Bottom spacing for floating button
                        Spacer()
                            .frame(height: 80)
                    }
                    .padding(.bottom, AppSpacing.md)
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
                .refreshable {
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                }
                
                // Modern Floating Action Button
                ModernFloatingAddButton(isPresented: $showingAddExpenseSheet)
            }
            .navigationTitle("Dashboard")
            .navigationBarHidden(true)
            .onAppear {
                ensureSettingsExist()
                updateSavingBuffer()
                
                // Staggered animations
                withAnimation(.easeOut(duration: 0.6)) {
                    headerOpacity = 1.0
                }
                withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                    cardsAppear = true
                }
            }
            .sheet(isPresented: $showingAddExpenseSheet) {
                AddExpenseView()
            }
        }
    }
    
    private func ensureSettingsExist() {
        if settings.isEmpty {
            let newSettings = UserSettings()
            newSettings.lastBufferUpdate = Date()
            modelContext.insert(newSettings)
        }
    }

    private func updateSavingBuffer() {
        guard let userSettings = settings.first else { return }
        let calendar = Calendar.current
        let now = Date()

        guard var lastUpdate = userSettings.lastBufferUpdate else {
            userSettings.lastBufferUpdate = now
            return
        }

        // Don't run if we're still in the same month as the last update
        if calendar.isDate(now, equalTo: lastUpdate, toGranularity: .month) {
            return
        }

        while !calendar.isDate(lastUpdate, equalTo: now, toGranularity: .month) {
            // Calculate surplus for the month of `lastUpdate`
            let expensesForMonth = expenses.filter {
                calendar.isDate($0.date, equalTo: lastUpdate, toGranularity: .month) &&
                $0.category?.type != .UTR
            }
            
            let grossSpent = expensesForMonth.reduce(0) { $0 + $1.amount }
            let totalRecovered = expensesForMonth
                .flatMap { $0.sharedParticipants }
                .reduce(0) { $0 + $1.amountPaid }
            let netSpent = grossSpent - totalRecovered
            
            let surplus = userSettings.expenseLimit - netSpent
            
            if surplus > 0 {
                userSettings.savingBuffer += surplus
            }

            // Move to the next month
            guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: lastUpdate) else {
                // This should not happen, but as a safeguard:
                userSettings.lastBufferUpdate = now
                break
            }
            lastUpdate = nextMonth
        }

        // After the loop, set the final update date
        userSettings.lastBufferUpdate = now
    }
}

// MARK: - Modern Header View
struct ModernHeaderView: View {
    private var monthYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: Date())
    }
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        default: return "Good Evening"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(greeting)
                .font(.subheadline)
                .foregroundColor(.textSecondary)
                .fontWeight(.medium)
            
            HStack(spacing: 0) {
                Text(monthYear)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.primaryGradient)
                
                Spacer()
            }
        }
    }
}

// MARK: - Spending Summary Card
struct SpendingSummaryCard: View {
    let amountSpent: Double
    let savingBuffer: Double
    
    var body: some View {
        HStack(spacing: AppSpacing.lg) {
            // Amount Spent
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundColor(.errorRed)
                        .font(.caption)
                    Text("Spent")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.textSecondary)
                }
                
                Text(amountSpent.toCurrency())
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.errorRed)
                    .monospacedDigit()
            }
            
            Spacer()
            
            // Divider
            Capsule()
                .fill(Color.divider.opacity(0.5))
                .frame(width: 1, height: 50)
            
            Spacer()
            
            // Saving Buffer
            VStack(alignment: .trailing, spacing: AppSpacing.xs) {
                HStack(spacing: 6) {
                    Text("Saving Buffer")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.textSecondary)
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundColor(.successGreen)
                        .font(.caption)
                }
                
                Text(savingBuffer.toCurrency())
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.successGreen)
                    .monospacedDigit()
            }
        }
        .padding(AppSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.large)
                .fill(Color.cardBackground)
                .cardShadow()
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppCornerRadius.large)
                .stroke(Color.divider.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Modern Section View
struct ModernSectionView<Content: View>: View {
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
            // Section Header
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(iconColor)
                
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                
                Spacer()
            }
            .padding(.horizontal, AppSpacing.md)
            
            // Section Content
            content
        }
    }
}

// MARK: - Recurring Expenses View
struct RecurringExpensesView: View {
    @Environment(\.modelContext) private var modelContext
    let templates: [RecurringExpenseTemplate]
    let expenses: [Expense]
    @State private var addedTemplateID: PersistentIdentifier?
    @State private var templateToEdit: RecurringExpenseTemplate?

    var body: some View {
        Group {
            if templates.isEmpty {
                // Modern Empty State
                VStack(spacing: AppSpacing.md) {
                    ZStack {
                        Circle()
                            .fill(Color.infoBlue.opacity(0.15))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "arrow.clockwise.circle")
                            .font(.system(size: 30))
                            .foregroundColor(.infoBlue)
                    }
                    
                    Text("No recurring expenses yet")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.lg)
                .padding(.horizontal, AppSpacing.md)
            } else {
                VStack(spacing: AppSpacing.sm) {
                    ForEach(templates) { template in
                        RecurringExpenseCard(
                            template: template,
                            isAdded: addedTemplateID == template.id,
                            onAdd: { addExpense(from: template) },
                            onEdit: { templateToEdit = template },
                            onDelete: { delete(template: template) }
                        )
                    }
                }
                .padding(.horizontal, AppSpacing.md)
            }
        }
        .sheet(item: $templateToEdit) { template in
            NavigationView {
                EditRecurringExpenseView(template: template)
            }
        }
    }

    private func addExpense(from template: RecurringExpenseTemplate) {
        let newExpense = Expense(
            amount: template.amount,
            date: Date(),
            time: Date(),
            category: template.category,
            reason: template.reason,
            isRecurring: false,
            isShared: false,
            sharedParticipants: [],
            recurringTemplate: template
        )
        modelContext.insert(newExpense)

        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            addedTemplateID = template.id
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.easeOut(duration: 0.3)) {
                addedTemplateID = nil
            }
        }
    }
    
    private func delete(template: RecurringExpenseTemplate) {
        withAnimation {
            modelContext.delete(template)
        }
    }
}

// MARK: - Recurring Expense Card
struct RecurringExpenseCard: View {
    let template: RecurringExpenseTemplate
    let isAdded: Bool
    let onAdd: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Category Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.primaryGradient.opacity(0.15))
                    .frame(width: 50, height: 50)
                
                Text(template.category?.iconName ?? "❓")
                    .font(.title2)
            }
            
            // Template Details
            VStack(alignment: .leading, spacing: 4) {
                Text(template.reason)
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                
                Text(template.amount.toCurrency())
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.textSecondary)
                    .monospacedDigit()
            }
            
            Spacer()
            
            // Add Button with Animation
            Button(action: onAdd) {
                ZStack {
                    if isAdded {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Color.successGreen)
                            .transition(.scale.combined(with: .opacity))
                    } else {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Color.brandCyan)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isAdded)
            }
            .buttonStyle(ScaleButtonStyle())
            .disabled(isAdded)
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
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }

            Button(action: onEdit) {
                Label("Edit", systemImage: "pencil")
            }
            .tint(.infoBlue)
        }
        .contextMenu {
            Button(action: onEdit) {
                Label("Edit", systemImage: "pencil")
            }
            
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Modern Floating Add Button
struct ModernFloatingAddButton: View {
    @Binding var isPresented: Bool
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            isPresented.toggle()
        }) {
            ZStack {
                // Shadow layer
                Circle()
                    .fill(Color.primaryGradient)
                    .frame(width: 60, height: 60)
                    .glowShadow(color: Color.brandMagenta)
                
                // Icon
                Image(systemName: "plus")
                    .font(.title2.weight(.semibold))
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(isPressed ? 135 : 0))
            }
        }
        .buttonStyle(FloatingButtonStyle(isPressed: $isPressed))
        .padding(AppSpacing.lg)
        .sensoryFeedback(.impact(weight: .medium), trigger: isPresented)
    }
}

// MARK: - Button Styles
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct FloatingButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, newValue in
                isPressed = newValue
            }
    }
}

// Legacy compatibility
struct ScaleOnPressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Extensions

extension Double {
    func toCurrency() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "INR"
        return formatter.string(from: NSNumber(value: self)) ?? ""
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        var body: some View {
            HomeView()
                .modelContainer(for: [Expense.self, UserSettings.self, Category.self, RecurringExpenseTemplate.self], inMemory: true)
        }
    }
    return PreviewWrapper()
}
