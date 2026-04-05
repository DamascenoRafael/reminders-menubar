import SwiftUI

struct SearchBarView: View {
    @EnvironmentObject var remindersData: RemindersData
    @ObservedObject var userPreferences = UserPreferences.shared

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .font(.callout)

            FocusableTextField(
                text: $remindersData.searchText,
                placeholder: rmbLocalized(.searchRemindersPlaceholder),
                onEscape: {
                    remindersData.showingSearch = false
                }
            )
            .font(.body)
        }
        .padding(8)
        .padding(.horizontal, 4)
        .background(
            Color.rmbColor(
                for: .textFieldBackground,
                isTransparencyEnabled: userPreferences.isTransparencyEnabled
            )
        )
        .cornerRadius(8)
        .padding(.horizontal, 14)
        .padding(.bottom, 6)
    }
}

private struct FocusableTextField: NSViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var onEscape: () -> Void

    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField()
        textField.placeholderString = placeholder
        textField.isBordered = false
        textField.drawsBackground = false
        textField.delegate = context.coordinator
        textField.font = .systemFont(ofSize: NSFont.systemFontSize)
        textField.cell?.sendsActionOnEndEditing = false
        DispatchQueue.main.async {
            textField.window?.makeFirstResponder(textField)
        }
        return textField
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        if nsView.stringValue != text {
            nsView.stringValue = text
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: FocusableTextField

        init(_ parent: FocusableTextField) {
            self.parent = parent
        }

        func controlTextDidChange(_ obj: Notification) {
            guard let textField = obj.object as? NSTextField else { return }
            parent.text = textField.stringValue
        }

        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
                parent.onEscape()
                return true
            }
            return false
        }
    }
}

#Preview {
    SearchBarView()
        .environmentObject(RemindersData())
}
