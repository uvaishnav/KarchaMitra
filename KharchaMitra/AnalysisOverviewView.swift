import SwiftUI
import SwiftData
import Charts

struct AnalysisOverviewView: View {
    @Query var expenses: [Expense]
    @Query var settings: [UserSettings]
    var isForPDF: Bool = false

    private var userSettings: UserSettings {
        settings.first ?? UserSettings()
    }

    private var monthlyExpenses: [Expense] {
        expenses.filter { Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .month) }
    }

    private var wantVsNeedSpending: [CategorySpending] {
        let dictionary = Dictionary(grouping: monthlyExpenses, by: { $0.category?.type ?? .need })
        return dictionary.map {
            CategorySpending(categoryName: $0.key.displayName, amount: $0.value.reduce(0) { $0 + $1.amount }, categoryType: $0.key)
        }
    }
    
    private var recurringVsOneTimeSpending: [SpendingType] {
        let recurringAmount = monthlyExpenses.filter { $0.recurringTemplate != nil }.reduce(0) { $0 + $1.amount }
        let oneTimeAmount = monthlyExpenses.filter { $0.recurringTemplate == nil }.reduce(0) { $0 + $1.amount }
        
        return [
            SpendingType(name: "Recurring", amount: recurringAmount),
            SpendingType(name: "One-Time", amount: oneTimeAmount)
        ]
    }
    
    private var totalSpending: Double {
        monthlyExpenses.reduce(0) { $0 + $1.amount }
    }
    
    private var monthlySpendingAgainstLimit: Double {
        let limitedExpenses = monthlyExpenses.filter { $0.category?.type != .UTR }
        
        let grossSpent = limitedExpenses.reduce(0) { $0 + $1.amount }
        
        let totalRecovered = limitedExpenses
            .flatMap { $0.sharedParticipants }
            .reduce(0) { $0 + $1.amountPaid }
            
        return grossSpent - totalRecovered
    }

    private var limitLeft: Double {
        userSettings.expenseLimit - monthlySpendingAgainstLimit
    }
    
    private var savingBuffer: Double {
        userSettings.savingBuffer
    }

    var body: some View {
        if isForPDF {
            content
        } else {
            ScrollView {
                content
            }
        }
    }
    
    private var content: some View {
        VStack(alignment: .leading, spacing: 24) {
            if monthlyExpenses.isEmpty {
                Text("Not enough data for this month yet.")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                // Monthly Summary
                GroupBox("Monthly Summary") {
                    HStack {
                        VStack {
                            Text("Spending")
                            Text(totalSpending.toCurrency()).foregroundColor(.red)
                        }
                        Spacer()
                        VStack {
                            Text("Limit Left")
                            Text(limitLeft.toCurrency()).foregroundColor(limitLeft >= 0 ? .green : .orange)
                        }
                        Spacer()
                        VStack {
                            Text("Saving Buffer")
                            Text(savingBuffer.toCurrency()).foregroundColor(.blue)
                        }
                    }
                }

                // Want vs Need Pie Chart
                GroupBox("Wants vs. Needs vs. UTR") {
                    Chart(wantVsNeedSpending) { spending in
                        SectorMark(
                            angle: .value("Amount", spending.amount),
                            innerRadius: .ratio(0.618)
                        )
                        .foregroundStyle(by: .value("Type", spending.categoryName))
                    }
                    .frame(height: 250)
                }

                // Recurring vs One-Time Pie Chart
                GroupBox("Recurring vs. One-Time") {
                    Chart(recurringVsOneTimeSpending) { spending in
                        SectorMark(
                            angle: .value("Amount", spending.amount),
                            innerRadius: .ratio(0.618)
                        )
                        .foregroundStyle(by: .value("Type", spending.name))
                    }
                    .frame(height: 250)
                }
            }
        }
        .padding()
    }
}
