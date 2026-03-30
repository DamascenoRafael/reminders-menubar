import SwiftUI

struct ConfirmButtonModifier: ViewModifier {
    @Environment(\.isEnabled) private var isEnabled

    @State private var isHovered = false

    func body(content: Content) -> some View {
        content
            .buttonStyle(.borderless)
            .foregroundColor(isEnabled ? .primary : .secondary)
            .background(Color.accentColor.opacity(backgroundOpacity))
            .cornerRadius(8)
            .onHover { hovering in
                isHovered = hovering
            }
    }

    private var backgroundOpacity: Double {
        if !isEnabled {
            return 0.25
        }
        return isHovered ? 1 : 0.75
    }
}
