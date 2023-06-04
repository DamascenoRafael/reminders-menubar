import SwiftUI

struct RmbHighlightedTextField: NSViewRepresentable {
    let placeholder: String
    var text: Binding<String>
    var highlightedTextRange: NSRange
    var onSubmit: () -> Void
    
    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField(frame: .infinite)
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
        attributedString.addAttribute(.foregroundColor,
                                      value: NSColor.systemBlue,
                                      range: highlightedTextRange)
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
    
    class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: RmbHighlightedTextField
        
        init(_ parent: RmbHighlightedTextField) {
            self.parent = parent
        }
        
        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            guard commandSelector == #selector(NSResponder.insertNewline(_:)),
                  !textView.string.isEmpty else {
                    return false
            }
                
            self.parent.onSubmit()
            return true
        }
        
        func controlTextDidChange(_ obj: Notification) {
            if let textField = obj.object as? NSTextField {
                parent.text.wrappedValue = textField.stringValue
            }
        }
    }
}
