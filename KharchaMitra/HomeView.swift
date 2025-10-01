import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showingAddExpenseSheet = false

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
                VStack(spacing: 0) {
                    HeaderView()
                        .padding(.horizontal)

                    List {
                        BudgetProgressView(
                            limit: userSettings.expenseLimit,
                            spending: monthlySpendingAgainstLimit,
                            safeLimit: safeLimit,
                            limitLeft: limitLeft
                        )

                        DashboardCard {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Amount Spent")
                                        .font(.headline)
                                        .fontWeight(.medium)
                                    Text(netMonthlyCashFlow.toCurrency())
                                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                                        .foregroundColor(.red)
                                }
                                Spacer()
                                VStack(alignment: .trailing) {
                                    Text("Saving Buffer")
                                        .font(.headline)
                                        .fontWeight(.medium)
                                    Text(userSettings.savingBuffer.toCurrency())
                                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding()
                        }
                        .padding(.horizontal)

                        DashboardCard {
                            QuickActionsView()
                        }
                        .padding(.horizontal)
                        
                        Section(header: Text("Recurring Expenses")) {
                            RecurringExpensesView(templates: recurringTemplates, expenses: expenses)
                        }
                        
                        Section(header: Text("Unsettled Shared Expenses")) {
                            UnsettledPaysView()
                        }
                    }
                    .listStyle(.plain)
                    .refreshable {
                        // In a real app, you might re-fetch data here.
                        // For now, SwiftData's live queries handle this.
                        // We can add a small delay to ensure the refresh indicator is visible.
                        try? await Task.sleep(nanoseconds: 1_000_000_000)
                    }
                }
                .background(Color(.systemGroupedBackground))
                
                FloatingAddButton(isPresented: $showingAddExpenseSheet)
            }
            .navigationTitle("Dashboard")
            .navigationBarHidden(true)
            .onAppear {
                ensureSettingsExist()
                updateSavingBuffer()
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
        guard let lastUpdate = userSettings.lastBufferUpdate else {
            userSettings.lastBufferUpdate = now
            return
        }
        
        if !calendar.isDate(now, equalTo: lastUpdate, toGranularity: .month) {
            guard let previousMonthDate = calendar.date(byAdding: .month, value: -1, to: now) else { return }
            let previousMonthExpenses = expenses.filter {
                calendar.isDate($0.date, equalTo: previousMonthDate, toGranularity: .month)
            }
            let totalSpentLastMonth = previousMonthExpenses.reduce(0) { $0 + $1.amount }
            let surplus = userSettings.expenseLimit - totalSpentLastMonth
            
            if surplus > 0 {
                userSettings.savingBuffer += surplus
            }
            userSettings.lastBufferUpdate = now
        }
    }
}

// MARK: - Subviews

struct DashboardCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .background(.regularMaterial)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

struct HeaderView: View {
    private var monthYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: Date())
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text(monthYear)
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top)
                .padding(.bottom, 2)
        }
    }
}

struct RecurringExpensesView: View {
    @Environment(\.modelContext) private var modelContext
    let templates: [RecurringExpenseTemplate]
    let expenses: [Expense]
    @State private var addedTemplateID: PersistentIdentifier?
    @State private var templateToEdit: RecurringExpenseTemplate?

    var body: some View {
        Group {
            if templates.isEmpty {
                Text("No recurring expenses set up yet.")
                    .foregroundColor(.secondary)
            } else {
                ForEach(templates) { template in
                    HStack {
                        Text(template.category?.iconName ?? "❓")
                            .font(.title)
                            .frame(width: 30)
                        
                        VStack(alignment: .leading) {
                            Text(template.reason)
                            Text(template.amount.toCurrency())
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if addedTemplateID == template.id {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title)
                                .foregroundColor(.green)
                                .transition(.scale.combined(with: .opacity))
                        } else {
                            Button(action: { addExpense(from: template) }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title)
                                    .foregroundColor(.blue)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        // Removed addExpense from here
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            delete(template: template)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }

                        Button {
                            templateToEdit = template
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
                    .contextMenu {
                        Button {
                            templateToEdit = template
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        
                        Button(role: .destructive) {
                            delete(template: template)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
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

        withAnimation {
            addedTemplateID = template.id
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                addedTemplateID = nil
            }
        }
    }
    
    private func delete(template: RecurringExpenseTemplate) {
        modelContext.delete(template)
    }
}

struct ScaleOnPressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct FloatingAddButton: View {
    @Binding var isPresented: Bool

    var body: some View {
        Button(action: {
            isPresented.toggle()
        }) {
            Image(systemName: "plus")
                .font(.title.weight(.semibold))
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .clipShape(Circle())
                .shadow(radius: 4, x: 0, y: 4)
        }
        .buttonStyle(ScaleOnPressButtonStyle())
        .padding()
        .sensoryFeedback(.impact(weight: .medium), trigger: isPresented)
    }
}


// MARK: - Extensions

extension Double {
    func toCurrency() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "INR" // Or use Locale.current.currencyCode
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
