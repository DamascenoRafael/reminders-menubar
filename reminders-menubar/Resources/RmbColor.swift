import SwiftUI

enum RmbColor {
    // Transparency-adaptive
    case backgroundTheme(isTransparent: Bool)
    case textFieldBackground(isTransparent: Bool)
    // Fixed
    case buttonHover
    case borderContrast
    case tagHighlight
    case dateHighlight
    case priorityHighlight
    case prioritySelectedBackground
    case confirmButtonBackground
    case upcomingSectionTitle
    case recentSectionTitle
    case expiredDate
    case destructiveAction
    case successIndicator
    case toastStroke
    case toastBackground

    var color: Color {
        switch self {
        case .backgroundTheme(let isTransparent):
            return adaptiveColor(
                "backgroundTheme",
                isTransparent: isTransparent
            )
        case .textFieldBackground(let isTransparent):
            return adaptiveColor(
                "textFieldBackground",
                isTransparent: isTransparent,
                transparentVariant: "textFieldBackgroundTransparent"
            )
        case .buttonHover:
            return Color("buttonHover")
        case .borderContrast:
            return Color("borderContrast")
        case .tagHighlight:
            return .purple
        case .dateHighlight:
            return .blue
        case .priorityHighlight:
            return .red
        case .prioritySelectedBackground:
            return .accentColor.opacity(0.4)
        case .confirmButtonBackground:
            return .accentColor
        case .upcomingSectionTitle:
            return .red
        case .recentSectionTitle:
            return .red
        case .expiredDate:
            return .red
        case .destructiveAction:
            return .red
        case .successIndicator:
            return .green
        case .toastStroke:
            return .gray.opacity(0.2)
        case .toastBackground:
            return Color("toastBackground")
        }
    }

    var nsColor: NSColor {
        NSColor(color)
    }

    private func adaptiveColor(
        _ name: String,
        isTransparent: Bool,
        transparentVariant: String? = nil
    ) -> Color {
        guard isTransparent else {
            return Color(name)
        }

        if let transparentVariant {
            return Color(transparentVariant)
        }

        return Color(name).opacity(0.3)
    }
}
