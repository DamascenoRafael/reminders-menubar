import SwiftUI

extension Color {
    static func rmbColor(for colorKey: RmbColorKey, and colorSchemeContrast: ColorSchemeContrast) -> Color {
        let isTransparencyEnabled = UserPreferences.shared.backgroundIsTransparent && colorSchemeContrast == .standard
        return colorKey.color(withTransparency: isTransparencyEnabled)
    }
}
