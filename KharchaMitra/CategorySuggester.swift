
import Foundation

// Uses the PredictionService to suggest a category.
class CategorySuggester {
    private let predictionService = PredictionService()

    /**
     Predicts a category by matching the name predicted by the service
     to one of the user's existing categories.
    */
    func predictCategory(from text: String, allCategories: [Category]) -> Category? {
        guard let predictedCategoryName = predictionService.predictCategoryName(from: text) else {
            return nil
        }
        
        // Find the category that matches the predicted name (case-insensitive)
        return allCategories.first { category in
            category.name.caseInsensitiveCompare(predictedCategoryName) == .orderedSame
        }
    }
}
