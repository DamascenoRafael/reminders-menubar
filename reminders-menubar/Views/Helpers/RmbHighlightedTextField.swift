import SwiftUI

struct RmbHighlightedTextField: NSViewRepresentable {
    struct HighlightedText {
        let range: NSRange
        let color: NSColor
    }
    
    let placeholder: String
    var text: Binding<String>
    var highlightedTexts: [HighlightedText]
    var isInitialCharValidToAutoComplete: (_ initialChar: String?) -> Bool
    var autoCompleteSuggestions: (_ typingWord: String) -> [String]
    var onSubmit: () -> Void
    
    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField(frame: .zero)
        textField.delegate = context.coordinator
        textField.placeholderAttributedString = getPlaceholderAttributedString(from: placeholder)
        textField.isBordered = false
        textField.backgroundColor = NSColor.clear
        textField.cell?.wraps = false
        textField.cell?.isScrollable = true
        textField.allowsEditingTextAttributes = true
        return textField
    }
    
    func updateNSView(_ nsView: NSTextField, context: Context) {
        nsView.attributedStringValue = getAttributedString(from: text.wrappedValue)
    }
    
    private func getAttributedString(from text: String) -> NSMutableAttributedString {
        let fullRange = text.fullRange
        
        let attributedString = NSMutableAttributedString(string: text)
        attributedString.beginEditing()
        attributedString.addAttribute(.font,
                                      value: NSFont.systemFont(ofSize: NSFont.systemFontSize),
                                      range: fullRange)
        attributedString.addAttribute(.foregroundColor,
                                      value: NSColor.labelColor,
                                      range: fullRange)
        for highlightedText in highlightedTexts {
            attributedString.addAttribute(.foregroundColor,
                                          value: highlightedText.color,
                                          range: highlightedText.range)
        }
        attributedString.endEditing()
        
        return attributedString
    }
    
    private func getPlaceholderAttributedString(from text: String) -> NSAttributedString {
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: NSColor.systemGray,
            .font: NSFont.preferredFont(forTextStyle: .callout)
        ]
        
        return NSAttributedString(string: text, attributes: attributes)
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextFieldDelegate, NSControlTextEditingDelegate {
        var parent: RmbHighlightedTextField
        
        var isAutoCompleting = false
        var isDeletePressed = false
        
        init(_ parent: RmbHighlightedTextField) {
            self.parent = parent
        }
        
        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.deleteBackward(_:))
                || commandSelector == #selector(NSResponder.deleteForward(_:)) {
                isDeletePressed = true
                return false
            }
            
            guard commandSelector == #selector(NSResponder.insertNewline(_:)),
                  !textView.string.isEmpty else {
                    return false
            }
                
            self.parent.onSubmit()
            return true
        }
        
        func controlTextDidChange(_ obj: Notification) {
            if let textField = obj.object as? NSTextField {
                if parent.text.wrappedValue == textField.stringValue {
                    // NOTE: When auto-completing the text may not have differences.
                    // We change the parent text to trigger the updateNSView.
                    parent.text.wrappedValue += " "
                }
                
                parent.text.wrappedValue = textField.stringValue
                
                if isDeletePressed {
                    isDeletePressed = false
                    return
                }
                
                if !isAutoCompleting {
                    isAutoCompleting = true
                    textField.currentEditor()?.complete(nil)
                    isAutoCompleting = false
                }
            }
        }
        
        func control(_ control: NSControl,
                     textView: NSTextView,
                     completions words: [String],
                     forPartialWordRange charRange: NSRange,
                     indexOfSelectedItem index: UnsafeMutablePointer<Int>) -> [String] {
            let typingWord = textView.string.substring(in: charRange)
            guard typingWord?.isEmpty == nil,
                  isValidToAutocomplete(textView.string, charRange: charRange) else {
                return []
            }
            
            return self.parent.autoCompleteSuggestions(typingWord ?? "")
        }
        
        private func isValidToAutocomplete(_ string: String, charRange: NSRange) -> Bool {
            let initialChar = string[safe: charRange.lowerBound - 1]
            let beforeInitialChar = string[safe: charRange.lowerBound - 2]
            
            return parent.isInitialCharValidToAutoComplete(initialChar)
                && (beforeInitialChar == " " || beforeInitialChar == nil)
        }
    }
}
