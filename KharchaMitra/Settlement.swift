
import Foundation
import SwiftData

@Model
final class Settlement {
    @Attribute(.unique) var id: UUID
    var amount: Double
    var date: Date
    var participantName: String

    init(id: UUID = UUID(), amount: Double, date: Date, participantName: String) {
        self.id = id
        self.amount = amount
        self.date = date
        self.participantName = participantName
    }
}
