import Foundation
import SwiftData

@Model
final class Category: Hashable {
    var name: String
    var type: CategoryType
    var iconName: String
    var colorHex: String

    init(name: String, type: CategoryType, iconName: String, colorHex: String) {
        self.name = name
        self.type = type
        self.iconName = iconName
        self.colorHex = colorHex
    }
}