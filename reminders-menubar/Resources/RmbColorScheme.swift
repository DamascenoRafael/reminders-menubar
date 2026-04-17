import SwiftUI

enum RmbColorScheme: String, CaseIterable {
    case system
    case light
    case dark
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }

    var title: String {
        switch self {
        case .system:
            return rmbLocalized(.appAppearanceColorSystemModeOption)
        case .light:
            return rmbLocalized(.appAppearanceColorLightModeOption)
        case .dark:
            return rmbLocalized(.appAppearanceColorDarkModeOption)
        }
    }
}
