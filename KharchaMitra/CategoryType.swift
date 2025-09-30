
import Foundation

enum CategoryType: Codable, Hashable {
    case want
    case need
    case UTR

    var displayName: String {
        switch self {
        case .need:
            return "Need"
        case .want:
            return "Want"
        case .UTR:
            return "UTR"
        }
    }
}
