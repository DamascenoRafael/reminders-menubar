import SwiftUI

struct ToolbarButtonModifier: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    
    @State private var isHovered = false

    func body(content: Content) -> some View {
        return content
            .padding(8)
            .buttonStyle(.borderless)
            .background(isHovered ? Color.rmbColor(for: .buttonHover, and: reduceTransparency) : nil)
            .cornerRadius(4)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}
