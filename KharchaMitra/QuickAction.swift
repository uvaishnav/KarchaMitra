
import Foundation
import SwiftData

@Model
final class QuickAction {
    var name: String
    var icon: String
    var reason: String?
    var amount: Double?
    @Relationship var category: Category?

    init(name: String, icon: String, reason: String? = nil, amount: Double? = nil, category: Category? = nil) {
        self.name = name
        self.icon = icon
        self.reason = reason
        self.amount = amount
        self.category = category
    }
}
