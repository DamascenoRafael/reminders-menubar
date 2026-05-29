import SwiftUI

struct RmbBackgroundModifier: ViewModifier {
    @ObservedObject private var userPreferences = UserPreferences.shared

    func body(content: Content) -> some View {
        content
            .background(
                Color.rmbColor(.backgroundTheme(isTransparent: userPreferences.isTransparencyEnabled))
                    .padding(-80)
            )
    }
}
