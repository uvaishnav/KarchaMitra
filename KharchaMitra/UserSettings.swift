
import Foundation
import SwiftData

@Model
final class UserSettings {
    var expenseLimit: Double
    var savingBuffer: Double
    var lastBufferUpdate: Date?

    init(expenseLimit: Double = 2000.0, savingBuffer: Double = 0, lastBufferUpdate: Date? = nil) {
        self.expenseLimit = expenseLimit
        self.savingBuffer = savingBuffer
        self.lastBufferUpdate = lastBufferUpdate
    }
}
