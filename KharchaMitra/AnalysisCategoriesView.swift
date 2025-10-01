import SwiftUI
import SwiftData

struct CategorySpendingInfo: Identifiable {
    let id: Category.ID
    let name: String
    let iconName: String
    let amount: Double
    let category: Category
}

struct AnalysisCategoriesView: View {
    @Query(sort: \Expense.date, order: .reverse) var expenses: [Expense]
    var isForPDF: Bool = false
    
    private var monthlyExpenses: [Expense] {
        expenses.filter { Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .month) }
    }
    
    private var categorySpendingData: [CategorySpendingInfo] {
        let dictionary = Dictionary(grouping: monthlyExpenses, by: { $0.category })
        
        return dictionary.compactMap { (category, expenses) -> CategorySpendingInfo? in
            guard let category = category else { return nil }
            let totalAmount = expenses.reduce(0) { $0 + $1.amount }
            return CategorySpendingInfo(id: category.id, name: category.name, iconName: category.iconName, amount: totalAmount, category: category)
        }.sorted(by: { $0.amount > $1.amount })
    }
    
    private func getSparklineData(for category: Category) -> [DailySpending] {
        let calendar = Calendar.current
        var dailyTotals: [Date: Double] = [:]
        
        // Initialize last 7 days with 0 amount
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -i, to: Date()) {
                let startOfDay = calendar.startOfDay(for: date)
                dailyTotals[startOfDay] = 0
            }
        }
        
        // Get expenses for the category in the last 7 days
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        let categoryExpenses = expenses.filter {
            $0.category?.id == category.id && $0.date >= sevenDaysAgo
        }
        
        // Sum expenses for each day
        for expense in categoryExpenses {
            let startOfDay = calendar.startOfDay(for: expense.date)
            dailyTotals[startOfDay, default: 0] += expense.amount
        }
        
        return dailyTotals.map { DailySpending(date: $0.key, amount: $0.value) }.sorted(by: { $0.date < $1.date })
    }

    var body: some View {
        if isForPDF {
            VStack(alignment: .leading) {
                ForEach(categorySpendingData) { spending in
                    HStack {
                        Text(spending.iconName)
                            .font(.largeTitle)
                            .frame(width: 50)
                        
                        VStack(alignment: .leading) {
                            Text(spending.name)
                                .font(.headline)
                            Text(spending.amount.toCurrency())
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    Divider()
                }
            }
        } else {
            List {
                ForEach(categorySpendingData) { spending in
                    NavigationLink(destination: CategoryDetailView(category: spending.category)) {
                        HStack {
                            Text(spending.iconName)
                                .font(.largeTitle)
                                .frame(width: 50)
                            
                            VStack(alignment: .leading) {
                                Text(spending.name)
                                    .font(.headline)
                                Text(spending.amount.toCurrency())
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            SparklineView(data: getSparklineData(for: spending.category))
                        }
                    }
                }
            }
        }
    }
}