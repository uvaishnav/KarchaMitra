import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var selectedTab: Int

    @Query var expenses: [Expense]
    @Query var settings: [UserSettings]
    @Query var recurringTemplates: [RecurringExpenseTemplate]

    private var userSettings: UserSettings {
        settings.first ?? UserSettings()
    }

    // Renamed from monthlySpent to be more descriptive. Represents total cash flow.
    private var netMonthlyCashFlow: Double {
        // Get all expenses for the current month
        let monthlyExpenses = expenses.filter { Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .month) }
        
        // Calculate the gross amount spent
        let grossSpent = monthlyExpenses.reduce(0) { $0 + $1.amount }
        
        // Calculate the total amount recovered from shared expenses
        let totalRecovered = monthlyExpenses
            .flatMap { $0.sharedParticipants }
            .reduce(0) { $0 + $1.amountPaid }
            
        // Net spent is the gross amount minus whatever has been paid back
        return grossSpent - totalRecovered
    }

    // New property to calculate only spending that counts against the limit
    private var monthlySpendingAgainstLimit: Double {
        // Get all non-UTR expenses for the month
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
        // Use the new property for the calculation
        userSettings.expenseLimit - monthlySpendingAgainstLimit
    }
    
    private var lastMonthRecurringTotal: Double {
        let calendar = Calendar.current
        guard let lastMonth = calendar.date(byAdding: .month, value: -1, to: Date()) else {
            return 0
        }
        guard let startOfLastMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: lastMonth)) else {
            return 0
        }
        guard let startOfThisMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: Date())) else {
            return 0
        }

        let lastMonthExpenses = expenses.filter { expense in
            return expense.date >= startOfLastMonth && expense.date < startOfThisMonth && expense.recurringTemplate != nil
        }
        return lastMonthExpenses.reduce(0) { $0 + $1.amount }
    }

    private var thisMonthRecurringSpent: Double {
        let calendar = Calendar.current
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: Date())) else {
            return 0
        }

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
    
    init(selectedTab: Binding<Int>) {
        _selectedTab = selectedTab
    }

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottomTrailing) {
                VStack {
                    HeaderView()
                    
                    BudgetProgressView(
                        limit: userSettings.expenseLimit,
                        spending: monthlySpendingAgainstLimit,
                        safeLimit: safeLimit,
                        limitLeft: limitLeft
                    )
                    
                    HStack {
                        VStack {
                            Text("Amount Spent")
                            Text(netMonthlyCashFlow.toCurrency()).foregroundColor(.red)
                        }
                        Spacer()
                        VStack {
                            Text("Saving Buffer")
                            Text(userSettings.savingBuffer.toCurrency()).foregroundColor(.blue)
                        }
                    }
                    .padding()

                    List {
                        Section(header: Text("Recurring Expenses")) {
                            RecurringExpensesView(templates: recurringTemplates, expenses: expenses)
                        }
                        
                        Section(header: Text("Unsettled Shared Expenses")) {
                            UnsettledPaysView()
                        }
                    }
                }
                .padding(.horizontal)

                FloatingAddButton(selectedTab: $selectedTab)
            }
            .navigationTitle("Dashboard")
            .navigationBarHidden(true)
            .onAppear {
                ensureSettingsExist()
                updateSavingBuffer()
            }
        }
    }
    
    private func ensureSettingsExist() {
        if settings.isEmpty {
            let newSettings = UserSettings()
            newSettings.lastBufferUpdate = Date() // Set initial date
            modelContext.insert(newSettings)
        }
    }

    private func updateSavingBuffer() {
        guard let userSettings = settings.first else { return }
        
        let calendar = Calendar.current
        let now = Date()
        
        // Ensure last update date exists, if not, set to now
        guard let lastUpdate = userSettings.lastBufferUpdate else {
            userSettings.lastBufferUpdate = now
            return
        }
        
        // Check if the current month is different from the last update month
        if !calendar.isDate(now, equalTo: lastUpdate, toGranularity: .month) {
            // Calculate the start of the previous month
            guard let previousMonthDate = calendar.date(byAdding: .month, value: -1, to: now) else { return }
            
            // Filter expenses for the previous month
            let previousMonthExpenses = expenses.filter {
                calendar.isDate($0.date, equalTo: previousMonthDate, toGranularity: .month)
            }
            
            let totalSpentLastMonth = previousMonthExpenses.reduce(0) { $0 + $1.amount }
            let surplus = userSettings.expenseLimit - totalSpentLastMonth
            
            // If there was a surplus, add it to the buffer
            if surplus > 0 {
                userSettings.savingBuffer += surplus
            }
            
            // Update the timestamp to the current date
            userSettings.lastBufferUpdate = now
        }
    }
}

// MARK: - Subviews

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
        }
    }
}

struct RecurringExpensesView: View {
    @Environment(\.modelContext) private var modelContext
    let templates: [RecurringExpenseTemplate]
    let expenses: [Expense]
    @State private var addedTemplateID: PersistentIdentifier?

    var body: some View {
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
                    } else {
                        Button(action: {
                            addExpense(from: template)
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title)
                        }
                    }
                }
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
            isRecurring: false, // The new expense itself is not a recurring template
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
}

struct FloatingAddButton: View {
    @Binding var selectedTab: Int

    var body: some View {
        Button(action: {
            selectedTab = 1 // Switch to the Add Expense tab
        }) {
            Image(systemName: "plus")
                .font(.title.weight(.semibold))
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .clipShape(Circle())
                .shadow(radius: 4, x: 0, y: 4)
        }
        .padding()
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
    // A wrapper view is needed for the preview to work with the binding.
    struct PreviewWrapper: View {
        @State private var selectedTab = 0
        var body: some View {
            HomeView(selectedTab: $selectedTab)
                .modelContainer(for: [Expense.self, UserSettings.self, Category.self, RecurringExpenseTemplate.self], inMemory: true)
        }
    }
    return PreviewWrapper()
}