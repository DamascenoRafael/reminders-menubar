import SwiftUI

extension Color {
    static func rmbColor(for colorKey: RmbColorKey, isTransparencyEnabled: Bool) -> Color {
        return colorKey.color(withTransparency: isTransparencyEnabled)
    }
}
