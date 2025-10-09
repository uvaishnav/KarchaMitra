import Foundation
import SwiftData

@Model
public final class Category: Hashable {
    public var name: String
    public var type: CategoryType
    public var iconName: String
    public var colorHex: String

    public init(name: String, type: CategoryType, iconName: String, colorHex: String) {
        self.name = name
        self.type = type
        self.iconName = iconName
        self.colorHex = colorHex
    }
}