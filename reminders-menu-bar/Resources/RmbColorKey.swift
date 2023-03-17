import SwiftUI

enum RmbColorKey: String {
    case buttonHover
    case backgroundTheme
    case textFieldBackground // textFieldBackgroundTransparent
    
    private var transparencyPostfix: String { "Transparent" }
    
    private var hasTransparencyPostfixString: Bool {
        switch self {
        case .textFieldBackground:
            return true
        default:
            return false
        }
    }
    
    private var hasTransparencyOpacityOption: Bool {
        switch self {
        case .backgroundTheme:
            return true
        default:
            return false
        }
    }
    
    func color(withTransparency isTransparencyEnabled: Bool) -> Color {
        guard isTransparencyEnabled else {
            return Color(rawValue)
        }
        
        if hasTransparencyPostfixString {
            return Color(rawValue + transparencyPostfix)
        }
        
        if hasTransparencyOpacityOption {
            return Color(rawValue).opacity(0.3)
        }
        
        return Color(rawValue)
    }
}
