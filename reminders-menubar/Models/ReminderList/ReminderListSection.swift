import SwiftUI

enum ReminderListSection: Identifiable, Equatable {
    case calendar(CalendarReminderList, hiddenUpcomingReminderCount: Int)
    case tag(TagReminderList, hiddenUpcomingReminderCount: Int)

    var id: String {
        switch self {
        case .calendar(let list, _):
            return "calendar-\(list.id)"
        case .tag(let list, _):
            return "tag-\(list.id)"
        }
    }

    var reminders: [ReminderItem] {
        switch self {
        case .calendar(let list, _):
            return list.reminders
        case .tag(let list, _):
            return list.reminders
        }
    }

    var title: String {
        switch self {
        case .calendar(let list, _):
            return list.calendar.title
        case .tag(let list, _):
            return "# \(list.tag.name)"
        }
    }

    var color: Color {
        switch self {
        case .calendar(let list, _):
            return Color(list.calendar.color)
        case .tag:
            return .rmbColor(.tagHighlight)
        }
    }

    var hiddenUpcomingReminderCount: Int {
        switch self {
        case .calendar(_, let count), .tag(_, let count):
            return count
        }
    }
}
