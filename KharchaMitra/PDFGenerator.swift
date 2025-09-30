import SwiftUI

class PDFGenerator {
    @MainActor
    func generate<V: View>(@ViewBuilder content: () -> V) -> URL? {
        let renderer = ImageRenderer(content: content())
        
        let outputFileURL = FileManager.default.temporaryDirectory.appendingPathComponent("KharchaMitra_Analysis.pdf")
        
        renderer.render { size, context in
            var box = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            
            guard let pdf = CGContext(outputFileURL as CFURL, mediaBox: &box, nil) else {
                return
            }
            
            pdf.beginPDFPage(nil)
            context(pdf)
            pdf.endPDFPage()
            pdf.closePDF()
        }
        
        return outputFileURL
    }
}
