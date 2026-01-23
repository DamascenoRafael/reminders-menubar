import SwiftUI

enum RmbColorScheme: String, CaseIterable {
    case light
    case dark
    
    var colorScheme: ColorScheme? {
        switch self {
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }

    var title: String {
        switch self {
        case .light:
            return rmbLocalized(.appAppearanceColorLightModeOptionButton)
        case .dark:
            return rmbLocalized(.appAppearanceColorDarkModeOptionButton)
        }
    }
}
