import SwiftUI

struct RmbBackgroundModifier: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    func body(content: Content) -> some View {
        content
            .background(Color.rmbColor(for: .backgroundTheme, and: reduceTransparency).padding(-80))
    }
}
