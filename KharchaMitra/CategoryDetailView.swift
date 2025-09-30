import SwiftUI
import SwiftData
import Charts

struct CategoryDetailView: View {
    let category: Category
    @Query var expenses: [Expense]
    
    private var monthlyExpenses: [Expense] {
        expenses.filter { $0.category?.id == category.id && Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .month) }
    }
    
    private var monthlySpendingData: [MonthlySpending] {
        let calendar = Calendar.current
        var spendingByMonth: [Date: Double] = [:]

        let categoryExpenses = expenses.filter { $0.category?.id == category.id }

        for expense in categoryExpenses {
            if let month = calendar.date(from: calendar.dateComponents([.year, .month], from: expense.date)) {
                spendingByMonth[month, default: 0] += expense.amount
            }
        }

        let last6Months = (0..<6).compactMap {
            calendar.date(byAdding: .month, value: -$0, to: Date())
        }
        
        return last6Months.map { monthDate in
            let monthComponent = calendar.date(from: calendar.dateComponents([.year, .month], from: monthDate))! // Force unwrap is safe here
            return MonthlySpending(date: monthDate, amount: spendingByMonth[monthComponent] ?? 0)
        }.sorted(by: { $0.date < $1.date })
    }
    
    var body: some View {
        VStack {
            GroupBox("Spending Trend (Last 6 Months)") {
                Chart(monthlySpendingData) { spending in
                    LineMark(
                        x: .value("Month", spending.month),
                        y: .value("Amount", spending.amount)
                    )
                }
                .frame(height: 200)
            }
            .padding()

            List {
                ForEach(monthlyExpenses) { expense in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(expense.reason ?? "Expense")
                            Text(expense.date.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text(expense.amount.toCurrency())
                    }
                }
            }
        }
        .navigationTitle(category.name)
    }
}
