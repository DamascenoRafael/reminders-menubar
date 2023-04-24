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
    case reminder4 = "icon-reminder-4"
    case reminder5 = "icon-reminder-5"
    case smalldot = "icon-small-dot"
    
    static var defaultIcon: RmbIcon {
        return self.note1
    }
    
    var image: NSImage {
        return NSImage(named: self.rawValue)!
    }

    var name: String {
        return self.rawValue
    }
}
