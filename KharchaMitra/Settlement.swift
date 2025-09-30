import Foundation
import SwiftData

@Model
final class Settlement {
    var amount: Double
    var date: Date
    var participantName: String

    init(amount: Double, date: Date, participantName: String) {
        self.amount = amount
        self.date = date
        self.participantName = participantName
    }
}