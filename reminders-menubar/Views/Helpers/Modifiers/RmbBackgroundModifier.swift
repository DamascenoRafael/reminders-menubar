import SwiftUI

struct RmbBackgroundModifier: ViewModifier {
    @ObservedObject private var userPreferences = UserPreferences.shared

    func body(content: Content) -> some View {
        content
            .background(
                Color.rmbColor(
                    for: .backgroundTheme,
                    isTransparencyEnabled: userPreferences.isTransparencyEnabled
                )
                .padding(-80)
            )
    }
}
