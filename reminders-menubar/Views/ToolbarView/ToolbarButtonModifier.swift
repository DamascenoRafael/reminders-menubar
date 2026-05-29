import SwiftUI

struct ToolbarButtonModifier: ViewModifier {
    @State private var isHovered = false

    func body(content: Content) -> some View {
        return content
            .buttonStyle(.borderless)
            .background(isHovered ? Color.rmbColor(.buttonHover) : nil)
            .cornerRadius(8)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}
