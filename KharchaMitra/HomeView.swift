
import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var selectedTab: Int

    @Query var expenses: [Expense]
    @Query var settings: [UserSettings]

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
    
    init(selectedTab: Binding<Int>) {
        _selectedTab = selectedTab
    }

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        HeaderView()

                        VStack(spacing: 15) {
                            SummaryCardView(title: "Amount Spent", value: netMonthlyCashFlow.toCurrency(), color: .red)
                            SummaryCardView(title: "Limit Left", value: limitLeft.toCurrency(), color: limitLeft >= 0 ? .green : .orange)
                            SummaryCardView(title: "Saving Buffer", value: userSettings.savingBuffer.toCurrency(), color: .blue)
                        }
                        
                        let recentExpenses = expenses.sorted(by: { $0.date > $1.date })
                        RecentExpensesView(expenses: Array(recentExpenses.prefix(5)))

                        UnsettledPaysView()
                            .padding(.top)

                        Spacer()
                    }
                    .padding(.horizontal)
                }

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
            
            // Note: This simple implementation handles one month at a time.
            // A more complex version could loop through all intervening months if the app hasn't been opened for a long time.
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
        Text(monthYear)
            .font(.largeTitle)
            .fontWeight(.bold)
            .padding(.top)
    }
}

struct RecentExpensesView: View {
    let expenses: [Expense]

    var body: some View {
        VStack(alignment: .leading) {
            Text("Recent Expenses")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.bottom, 5)

            if expenses.isEmpty {
                Text("No expenses recorded yet.")
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
            } else {
                VStack(spacing: 10) {
                    ForEach(expenses) { expense in
                        HStack {
                            Image(systemName: expense.category?.iconName ?? "questionmark.circle")
                                .font(.headline)
                                .frame(width: 30)
                                .accessibilityHidden(true)
                            
                            VStack(alignment: .leading) {
                                Text(expense.reason?.isEmpty == false ? expense.reason! : expense.category?.name ?? "Uncategorized")
                                Text(expense.date.formatted(date: .numeric, time: .omitted))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text(expense.amount.toCurrency())
                                .fontWeight(.semibold)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(expense.reason ?? expense.category?.name ?? "Expense"), \(expense.amount.toCurrency()), \(expense.date.formatted(date: .abbreviated, time: .omitted))")
                    }
                }
                .animation(.default, value: expenses)
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

// Reusable Summary Card View
struct SummaryCardView: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }
            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
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
                .modelContainer(for: [Expense.self, UserSettings.self, Category.self], inMemory: true)
        }
    }
    return PreviewWrapper()
}
