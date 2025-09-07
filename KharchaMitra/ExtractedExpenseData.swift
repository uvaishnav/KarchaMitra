
import Foundation

// A struct to hold data extracted from a receipt scan.
struct ExtractedExpenseData {
    var amount: Double?
    var date: Date?
    var merchant: String?
    var currencyCode: String? = "USD"
}
