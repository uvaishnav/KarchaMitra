
import UIKit

// Placeholder service for receipt scanning.
class ReceiptScannerService {
    
    // Simulates scanning a receipt image and returns hardcoded data.
    // In a real implementation, this would use VisionKit and OCR.
    func scanReceipt(image: UIImage, completion: @escaping (ExtractedExpenseData) -> Void) {
        // Simulate a delay to mimic processing time.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // Return hardcoded data for demonstration purposes.
            let extractedData = ExtractedExpenseData(
                amount: 42.99,
                date: Date(),
                merchant: "SuperMart Groceries"
            )
            completion(extractedData)
        }
    }
}
