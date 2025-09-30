import Foundation
import SwiftData

@Model
final class SharedParticipant {
    var name: String
    var amountOwed: Double
    var amountPaid: Double
    var contactIdentifier: String?

    init(name: String, amountOwed: Double, amountPaid: Double = 0, contactIdentifier: String? = nil) {
        self.name = name
        self.amountOwed = amountOwed
        self.amountPaid = amountPaid
        self.contactIdentifier = contactIdentifier
    }

    var amountRemaining: Double {
        amountOwed - amountPaid
    }
}