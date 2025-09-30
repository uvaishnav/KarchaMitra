import Foundation
import SwiftData

@Model
final class Expense {
    var amount: Double
    var date: Date
    var time: Date
    @Relationship(deleteRule: .nullify) var category: Category?
    var reason: String?
    var isRecurring: Bool
    var isShared: Bool
    @Relationship(deleteRule: .cascade) var sharedParticipants: [SharedParticipant]
    var createdAt: Date
    var recurringTemplate: RecurringExpenseTemplate?

    init(amount: Double, date: Date, time: Date, category: Category? = nil, reason: String? = nil, isRecurring: Bool = false, isShared: Bool = false, sharedParticipants: [SharedParticipant] = [], createdAt: Date = .now, recurringTemplate: RecurringExpenseTemplate? = nil) {
        self.amount = amount
        self.date = date
        self.time = time
        self.category = category
        self.reason = reason
        self.isRecurring = isRecurring
        self.isShared = isShared
        self.sharedParticipants = sharedParticipants
        self.createdAt = createdAt
        self.recurringTemplate = recurringTemplate
    }
}
