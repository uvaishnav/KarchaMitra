
import Foundation
import SwiftData

@Model
final class SharedParticipant {
    @Attribute(.unique) var id: UUID
    var name: String
    var amountOwed: Double
    var amountPaid: Double
    var contactIdentifier: String?

    init(id: UUID = UUID(), name: String, amountOwed: Double, amountPaid: Double = 0, contactIdentifier: String? = nil) {
        self.id = id
        self.name = name
        self.amountOwed = amountOwed
        self.amountPaid = amountPaid
        self.contactIdentifier = contactIdentifier
    }

    var amountRemaining: Double {
        amountOwed - amountPaid
    }
}
