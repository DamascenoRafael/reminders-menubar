import SwiftUI

struct RmbHighlightedTextField: NSViewRepresentable {
    struct HighlightedText {
        let range: NSRange
        let color: NSColor
    }

    let placeholder: String
    var text: Binding<String>
    var highlightedTexts: [HighlightedText]
    var textContainerDynamicHeight: Binding<CGFloat>?
    var maximumNumberOfLines: Int
    var allowNewLineAndTab: Bool
    var focusTrigger: Binding<UUID>?

    private var lastFocusTrigger: UUID?

    private var textFont = NSFont.systemFont(ofSize: NSFont.systemFontSize)
    private var onSubmit: (() -> Void)?
    private var isInitialCharValidToAutoComplete: ((_ initialChar: String?) -> Bool)?
    private var autoCompleteSuggestions: ((_ typingWord: String) -> [String])?

    init(
        placeholder: String,
        text: Binding<String>,
        highlightedTexts: [HighlightedText] = [],
        textContainerDynamicHeight: Binding<CGFloat>? = nil,
        maximumNumberOfLines: Int = 3,
        allowNewLineAndTab: Bool = false,
        focusTrigger: Binding<UUID>? = nil
    ) {
        self.placeholder = placeholder
        self.text = text
        self.highlightedTexts = highlightedTexts
        self.textContainerDynamicHeight = textContainerDynamicHeight
        self.maximumNumberOfLines = maximumNumberOfLines
        self.allowNewLineAndTab = allowNewLineAndTab
        self.focusTrigger = focusTrigger
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = PlaceholderNSTextView.scrollableTextView()
        guard let textView = scrollView.documentView as? PlaceholderNSTextView else {
            return scrollView
        }

        textView.placeholder = placeholder
        textView.shouldFocus = focusTrigger != nil
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.backgroundColor = .clear
        textView.font = textFont
        textView.delegate = context.coordinator

        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else {
            return
        }

        if let trigger = focusTrigger?.wrappedValue,
           trigger != context.coordinator.parent.lastFocusTrigger,
           nsView.window?.firstResponder != textView {
            context.coordinator.parent.lastFocusTrigger = trigger
            nsView.window?.makeFirstResponder(textView)
        }

        let selectedRange = textView.selectedRange()
        textView.textStorage?.setAttributedString(getAttributedString(from: text.wrappedValue))
        textView.setSelectedRange(selectedRange)

        textView.scrollRangeToVisible(NSRange(location: text.wrappedValue.count, length: 0))

        adjustDynamicHeight(for: textView, context: context)
    }

    private func adjustDynamicHeight(for textView: NSTextView, context: Context) {
        var newHeight: CGFloat = 48.0
        if let layoutManager = textView.layoutManager,
           let textContainer = textView.textContainer {
            let maxHeight = layoutManager.defaultLineHeight(for: textFont) * CGFloat(maximumNumberOfLines)
            newHeight = min(layoutManager.usedRect(for: textContainer).height, maxHeight)
        }

        DispatchQueue.main.async {
            context.coordinator.parent.textContainerDynamicHeight?.wrappedValue = newHeight
        }
    }

    private func getAttributedString(from text: String) -> NSMutableAttributedString {
        let fullRange = text.fullRange

        let attributedString = NSMutableAttributedString(string: text)
        attributedString.beginEditing()
        attributedString.addAttribute(
            .font,
            value: textFont,
            range: fullRange
        )
        attributedString.addAttribute(
            .foregroundColor,
            value: NSColor.labelColor,
            range: fullRange
        )
        for highlightedText in highlightedTexts {
            attributedString.addAttribute(
                .foregroundColor,
                value: highlightedText.color,
                range: highlightedText.range
            )
        }
        attributedString.endEditing()

        return attributedString
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    class Coordinator: NSObject, NSTextViewDelegate, NSTextDelegate {
        var parent: RmbHighlightedTextField

        var isAutoCompleting = false
        var isDeletePressed = false

        init(_ parent: RmbHighlightedTextField) {
            self.parent = parent
        }

        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.deleteBackward(_:))
                || commandSelector == #selector(NSResponder.deleteForward(_:)) {
                isDeletePressed = true
                return false
            }

            if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
                if !textView.string.isEmpty {
                    parent.text.wrappedValue = ""
                    return true
                }
                return false
            }

            guard commandSelector == #selector(NSResponder.insertNewline(_:)),
                  !textView.string.isEmpty else {
                return false
            }

            guard let onSubmit = parent.onSubmit else {
                return false
            }

            onSubmit()
            return true
        }

        func textView(
            _ textView: NSTextView,
            shouldChangeTextIn affectedCharRange: NSRange,
            replacementString: String?
        ) -> Bool {
            guard let replacementString else {
                return true
            }

            if !parent.allowNewLineAndTab && (replacementString == "\n" || replacementString == "\t") {
                return false
            }

            return true
        }

        func textDidChange(_ obj: Notification) {
            guard let textView = obj.object as? NSTextView else {
                return
            }

            if parent.text.wrappedValue == textView.string {
                // NOTE: When auto-completing the text may not have differences.
                // We change the parent text to trigger the updateNSView.
                parent.text.wrappedValue += " "
            }

            parent.text.wrappedValue = textView.string

            if isDeletePressed {
                isDeletePressed = false
                return
            }

            if !isAutoCompleting {
                isAutoCompleting = true
                textView.complete(nil)
                isAutoCompleting = false
            }
        }

        func textView(
            _ textView: NSTextView,
            completions words: [String],
            forPartialWordRange charRange: NSRange,
            indexOfSelectedItem index: UnsafeMutablePointer<Int>?
        ) -> [String] {
            guard let autoCompleteSuggestions = parent.autoCompleteSuggestions else {
                return []
            }

            let typingWord = textView.string.substring(in: charRange)
            guard !typingWord.isEmpty,
                  isValidToAutocomplete(textView.string, charRange: charRange) else {
                return []
            }

            return autoCompleteSuggestions(typingWord)
        }

        private func isValidToAutocomplete(_ string: String, charRange: NSRange) -> Bool {
            guard let isInitialCharValidToAutoComplete = parent.isInitialCharValidToAutoComplete else {
                return false
            }

            let initialChar = string[safe: charRange.lowerBound - 1]
            let beforeInitialChar = string[safe: charRange.lowerBound - 2]

            return isInitialCharValidToAutoComplete(initialChar)
            && (beforeInitialChar == " " || beforeInitialChar == nil)
        }
    }
}

extension RmbHighlightedTextField {
    func onSubmit(_ onSubmit: @escaping () -> Void) -> RmbHighlightedTextField {
        var view = self
        view.onSubmit = onSubmit
        return view
    }

    func autoComplete(
        isInitialCharValid: @escaping (_ initialChar: String?) -> Bool,
        suggestions: @escaping (_ typingWord: String) -> [String]
    ) -> RmbHighlightedTextField {
        var view = self
        view.isInitialCharValidToAutoComplete = isInitialCharValid
        view.autoCompleteSuggestions = suggestions
        return view
    }

    func fontStyle(_ fontStyle: NSFont.TextStyle) -> RmbHighlightedTextField {
        var view = self
        view.textFont = .preferredFont(forTextStyle: fontStyle)
        return view
    }
}

private class PlaceholderNSTextView: NSTextView {
    var placeholder: String = ""
    var shouldFocus: Bool = false

    override func draw(_ rect: CGRect) {
        if string.isEmpty && !placeholder.isEmpty {
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font ?? .systemFont(ofSize: NSFont.systemFontSize),
                .foregroundColor: NSColor.secondaryLabelColor
            ]

            placeholder.draw(in: rect.insetBy(dx: 4, dy: 0), withAttributes: attributes)
        }
        super.draw(rect)
    }

    override func viewDidMoveToWindow() {
        if shouldFocus {
            window?.makeFirstResponder(self)
        }
    }
}
