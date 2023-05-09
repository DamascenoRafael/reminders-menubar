import SwiftUI

struct OnKeyboardShortcut: ViewModifier {
    let shortcut: KeyboardShortcut
    let action: () -> Void
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Button("", action: action)
                    .labelsHidden()
                    .opacity(0)
                    .frame(width: 0, height: 0)
                    .keyboardShortcut(shortcut)
                    .accessibilityHidden(true)
            )
    }
}
