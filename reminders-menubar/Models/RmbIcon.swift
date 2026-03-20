import Cocoa

enum RmbIcon: String, CaseIterable {
    case note1 = "icon-note-1"
    case note2 = "icon-note-2"
    case note3 = "icon-note-3"
    case note4 = "icon-note-4"
    case note5 = "icon-note-5"
    case bell1 = "icon-bell-1"
    case bell2 = "icon-bell-2"
    case reminder1 = "icon-reminder-1"
    case reminder2 = "icon-reminder-2"
    case reminder3 = "icon-reminder-3"
    case sfsymbols1 = "checklist"
    case sfsymbols2 = "circle.inset.filled"
    case smalldot = "icon-small-dot"
    
    static var defaultIcon: RmbIcon {
        return self.note1
    }
    
    var image: NSImage {
        if let assetImage = NSImage(named: self.rawValue) {
            return assetImage
        }
        if let sfSymbol = NSImage(systemSymbolName: self.rawValue, accessibilityDescription: name) {
            return sfSymbol
        }
        return Self.defaultIcon.image
    }

    var name: String {
        switch self {
        case .note1:
            return "Note 1"
        case .note2:
            return "Note 2"
        case .note3:
            return "Note 3"
        case .note4:
            return "Note 4"
        case .note5:
            return "Note 5"
        case .bell1:
            return "Bell 1"
        case .bell2:
            return "Bell 2"
        case .reminder1:
            return "Reminder 1"
        case .reminder2:
            return "Reminder 2"
        case .reminder3:
            return "Reminder 3"
        case .sfsymbols1:
            return "Checklist"
        case .sfsymbols2:
            return "Circle"
        case .smalldot:
            return "Small Dot"
        }
    }
}
