import SwiftUI

enum RmbColorScheme: String {
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
}
