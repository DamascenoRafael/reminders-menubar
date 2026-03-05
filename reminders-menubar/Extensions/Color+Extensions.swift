import SwiftUI

extension Color {
    static func rmbColor(for colorKey: RmbColorKey, and reduceTransparency: Bool) -> Color {
        let isTransparencyEnabled = UserPreferences.shared.backgroundIsTransparent && !reduceTransparency
        return colorKey.color(withTransparency: isTransparencyEnabled)
    }
}
