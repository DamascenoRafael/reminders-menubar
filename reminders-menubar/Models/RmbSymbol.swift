import SwiftUI

enum RmbSymbol {
    case recentReminders
    case alarm
    case flag
    case flagFill
    case priorityHigh
    case priorityMedium
    case priorityLow
    case menubarRectangle
    case arrowDownCircle
    case calendar
    case calendarBadgeExclamationmark
    case checkmark
    case checkmarkCircleFill
    case chevronDown
    case chevronRight
    case chevronUp
    case circle
    case clock
    case docOnDoc
    case ellipsis
    case envelope
    case folder
    case gearshape
    case infoCircle
    case keyboard
    case circleFilled
    case filterCircle
    case link
    case listBullet
    case magnifyingglass
    case hashtag
    case pencil
    case pin
    case plus
    case recurrence
    case safari
    case tray
    case trash
    case xmark
    case xmarkCircleFill

    var name: String {
        switch self {
        case .recentReminders:
            if #available(macOS 15, *) {
                return "clock.arrow.trianglehead.counterclockwise.rotate.90"
            } else if #available(macOS 13, *) {
                return "clock.arrow.circlepath"
            } else {
                return "clock"
            }
        case .alarm:
            return "alarm"
        case .flag:
            return "flag"
        case .flagFill:
            return "flag.fill"
        case .priorityHigh:
            if #available(macOS 13, *) {
                return "exclamationmark.3"
            } else {
                return "exclamationmark"
            }
        case .priorityMedium:
            if #available(macOS 13, *) {
                return "exclamationmark.2"
            } else {
                return "exclamationmark"
            }
        case .priorityLow:
            return "exclamationmark"
        case .menubarRectangle:
            if #available(macOS 12, *) {
                return "menubar.rectangle"
            } else {
                return "rectangle"
            }
        case .arrowDownCircle:
            return "arrow.down.circle"
        case .calendar:
            return "calendar"
        case .calendarBadgeExclamationmark:
            return "calendar.badge.exclamationmark"
        case .checkmark:
            return "checkmark"
        case .checkmarkCircleFill:
            return "checkmark.circle.fill"
        case .chevronDown:
            return "chevron.down"
        case .chevronRight:
            return "chevron.right"
        case .chevronUp:
            return "chevron.up"
        case .circle:
            return "circle"
        case .clock:
            return "clock"
        case .docOnDoc:
            return "doc.on.doc"
        case .ellipsis:
            return "ellipsis"
        case .envelope:
            return "envelope"
        case .folder:
            return "folder"
        case .gearshape:
            return "gearshape"
        case .infoCircle:
            return "info.circle"
        case .keyboard:
            return "keyboard"
        case .circleFilled:
            if #available(macOS 13, *) {
                return "circle.inset.filled"
            } else {
                return "largecircle.fill.circle"
            }
        case .filterCircle:
            return "line.horizontal.3.decrease.circle"
        case .link:
            return "link"
        case .listBullet:
            return "list.bullet"
        case .magnifyingglass:
            return "magnifyingglass"
        case .hashtag:
            return "number"
        case .pencil:
            return "pencil"
        case .pin:
            return "pin"
        case .plus:
            return "plus"
        case .recurrence:
            return "repeat"
        case .safari:
            return "safari"
        case .tray:
            return "tray"
        case .trash:
            return "trash"
        case .xmark:
            return "xmark"
        case .xmarkCircleFill:
            return "xmark.circle.fill"
        }
    }
}
