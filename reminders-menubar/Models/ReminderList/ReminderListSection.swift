import SwiftUI

enum ReminderListSection: Identifiable, Equatable {
    case calendar(ReminderList)
    case tag(TagReminderList)

    var id: String {
        switch self {
        case .calendar(let list):
            return "calendar-\(list.id)"
        case .tag(let list):
            return "tag-\(list.id)"
        }
    }

    var reminders: [ReminderItem] {
        switch self {
        case .calendar(let list):
            return list.reminders
        case .tag(let list):
            return list.reminders
        }
    }

    var title: String {
        switch self {
        case .calendar(let list):
            return list.calendar.title
        case .tag(let list):
            return "# \(list.tag.name)"
        }
    }

    var color: Color {
        switch self {
        case .calendar(let list):
            return Color(list.calendar.color)
        case .tag:
            return .rmbColor(.tagHighlight)
        }
    }
}
