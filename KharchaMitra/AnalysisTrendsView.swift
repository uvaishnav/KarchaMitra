import SwiftUI
import SwiftData
import Charts

struct MonthlySpending: Identifiable {
    let id = UUID()
    let date: Date
    let amount: Double
    
    var month: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: date)
    }
}

struct AnalysisTrendsView: View {
    @Query(sort: \Expense.date, order: .reverse) var expenses: [Expense]
    var isForPDF: Bool = false
    
    private var monthlySpendingData: [MonthlySpending] {
        let calendar = Calendar.current
        var spendingByMonth: [Date: Double] = [:]

        for expense in expenses {
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
    
    private var categorySpendingData: [CategorySpending] {
        let calendar = Calendar.current
        guard let sixMonthsAgo = calendar.date(byAdding: .month, value: -6, to: Date()) else {
            return []
        }

        let recentExpenses = expenses.filter { $0.date >= sixMonthsAgo }
        
        let dictionary = Dictionary(grouping: recentExpenses, by: { $0.category })
        
        return dictionary.compactMap { (category, expenses) -> CategorySpending? in
            guard let category = category else { return nil }
            let totalAmount = expenses.reduce(0) { $0 + $1.amount }
            return CategorySpending(categoryName: category.name, amount: totalAmount, categoryType: category.type)
        }.sorted(by: { $0.amount > $1.amount })
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
            GroupBox("Monthly Spending (Last 6 Months)") {
                Chart(monthlySpendingData) { spending in
                    LineMark(
                        x: .value("Month", spending.month),
                        y: .value("Amount", spending.amount)
                    )
                    PointMark(
                        x: .value("Month", spending.month),
                        y: .value("Amount", spending.amount)
                    )
                }
                .frame(height: 300)
            }
            
            GroupBox("Spending by Category (Last 6 Months)") {
                Chart(categorySpendingData) { spending in
                    BarMark(
                        x: .value("Amount", spending.amount),
                        y: .value("Category", spending.categoryName)
                    )
                    .foregroundStyle(by: .value("Category", spending.categoryName))
                }
                .chartLegend(.hidden)
                .frame(height: 300)
            }
        }
        .padding()
    }
}