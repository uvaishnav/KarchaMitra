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
                        }
                    }
                }
            }
        }
    }
}
