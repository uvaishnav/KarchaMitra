import SwiftUI
import UIKit

struct EmojiTextField: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.delegate = context.coordinator
        textField.placeholder = placeholder
        textField.textAlignment = .center
        textField.font = .systemFont(ofSize: 28)
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = text
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: EmojiTextField

        init(_ parent: EmojiTextField) {
            self.parent = parent
        }

        func textFieldDidChangeSelection(_ textField: UITextField) {
            DispatchQueue.main.async {
                self.parent.text = textField.text ?? ""
            }
        }
        
        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            let newText = (textField.text as NSString?)?.replacingCharacters(in: range, with: string) ?? string

            // Allow the user to clear the text field
            if newText.isEmpty {
                return true
            }

            // Ensure the new text is a single emoji
            guard newText.isSingleEmoji else {
                return false
            }

            return true
        }
    }
}

extension String {
    var isSingleEmoji: Bool {
        // A string is considered a single emoji if it has exactly one grapheme cluster
        // and that cluster is composed of unicode scalars that are emojis.
        guard self.count == 1 else { return false }
        
        // Check if the character's scalars fall into common emoji ranges.
        // This is not an exhaustive list but covers the vast majority of emojis.
        for scalar in self.unicodeScalars {
            switch scalar.value {
            case 0x1F600...0x1F64F, // Emoticons
                 0x1F300...0x1F5FF, // Miscellaneous Symbols and Pictographs
                 0x1F680...0x1F6FF, // Transport and Map Symbols
                 0x2600...0x26FF,   // Miscellaneous Symbols
                 0x2700...0x27BF,   // Dingbats
                 0xFE00...0xFE0F,   // Variation Selectors
                 0x1F900...0x1F9FF, // Supplemental Symbols and Pictographs
                 0x1F1E6...0x1F1FF: // Regional Indicator Symbols (flags)
                return true
            default:
                continue
            }
        }
        
        return false
    }
}