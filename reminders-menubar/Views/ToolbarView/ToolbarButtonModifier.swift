import SwiftUI

struct ToolbarButtonModifier: ViewModifier {
    var isActive = false
    @State private var isHovered = false

    func body(content: Content) -> some View {
        return content
            .buttonStyle(.borderless)
            .background((isHovered || isActive) ? Color.rmbColor(.buttonHover) : nil)
            .cornerRadius(8)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}
