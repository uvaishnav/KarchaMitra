
import Foundation
import SwiftData

@Model
final class Category {
    @Attribute(.unique) var id: UUID
    var name: String
    var type: CategoryType
    var iconName: String
    var colorHex: String

    init(id: UUID = UUID(), name: String, type: CategoryType, iconName: String, colorHex: String) {
        self.id = id
        self.name = name
        self.type = type
        self.iconName = iconName
        self.colorHex = colorHex
    }
}
