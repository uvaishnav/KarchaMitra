
import Foundation

// This service simulates interactions with an on-device Core ML model.
class PredictionService {

    /**
     Simulates predicting an expense category from a given text, like a merchant name.
     In a real app, this would pass the text to a text classification Core ML model.
    */
    func predictCategoryName(from text: String) -> String? {
        let lowercasedText = text.lowercased()
        
        // Simple hardcoded rules to simulate a model's predictions
        if lowercasedText.contains("coffee") || lowercasedText.contains("starbucks") {
            return "Coffee"
        } else if lowercasedText.contains("grocery") || lowercasedText.contains("supermart") {
            return "Groceries"
        } else if lowercasedText.contains("ride") || lowercasedText.contains("uber") {
            return "Transport"
        } else if lowercasedText.contains("pizza") || lowercasedText.contains("restaurant") {
            return "Dining Out"
        }
        
        return nil
    }
    
    /**
     Simulates generating a financial insight based on a collection of expenses.
     In a real app, this might use a more complex model or a set of heuristic rules.
    */
    func generateInsight(from expenses: [Expense]) -> String {
        guard !expenses.isEmpty else {
            return "Not enough data to generate insights. Keep tracking your expenses!"
        }
        
        let totalSpent = expenses.reduce(0) { $0 + $1.amount }
        let wantExpenses = expenses.filter { $0.category?.type == .want }
        let totalWantSpending = wantExpenses.reduce(0) { $0 + $1.amount }
        
        if totalWantSpending > totalSpent / 2 {
            return "Over half of your spending this month has been on 'Wants'. Consider reviewing these to boost your savings."
        }
        
        if let mostExpensive = expenses.max(by: { $0.amount < $1.amount }) {
            let categoryName = mostExpensive.category?.name ?? "Uncategorized"
            return "Your largest single expense this month was \(mostExpensive.amount.toCurrency()) in the ' \(categoryName)' category."
        }
        
        return "You're doing a great job tracking your expenses! Keep it up."
    }
}
