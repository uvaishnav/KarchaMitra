import SwiftData

@Model
class RecurringExpenseTemplate {
    var amount: Double
    @Relationship(deleteRule: .nullify)
    var category: Category?
    var reason: String
    
    init(amount: Double, category: Category?, reason: String) {
        self.amount = amount
        self.category = category
        self.reason = reason
    }
}