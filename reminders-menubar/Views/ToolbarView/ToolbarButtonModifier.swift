import SwiftUI

struct ToolbarButtonModifier: ViewModifier {
    @ObservedObject private var userPreferences = UserPreferences.shared
    
    @State private var isHovered = false

    func body(content: Content) -> some View {
        return content
            .buttonStyle(.borderless)
            .background(
                isHovered
                    ? Color.rmbColor(
                        for: .buttonHover,
                        isTransparencyEnabled: userPreferences.isTransparencyEnabled
                    )
                    : nil
            )
            .cornerRadius(8)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}
