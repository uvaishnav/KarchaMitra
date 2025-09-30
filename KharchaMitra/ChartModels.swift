import Foundation

struct CategorySpending: Identifiable {
    let id = UUID()
    let categoryName: String
    let amount: Double
    let categoryType: CategoryType
}

struct SpendingType: Identifiable {
    let id = UUID()
    let name: String
    let amount: Double
}
