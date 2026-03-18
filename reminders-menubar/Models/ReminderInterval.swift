import Foundation

enum ReminderInterval: String, Codable, CaseIterable {
    case due
    case today
    case week
    case month
    case all

    var sectionTitle: String {
        switch self {
        case .due:
            return rmbLocalized(.upcomingRemindersDueSectionTitle)
        case .today:
            return rmbLocalized(.upcomingRemindersTodaySectionTitle)
        case .week:
            return rmbLocalized(.upcomingRemindersInAWeekSectionTitle)
        case .month:
            return rmbLocalized(.upcomingRemindersInAMonthSectionTitle)
        case .all:
            return rmbLocalized(.upcomingRemindersScheduledSectionTitle)
        }
    }

    var filterOption: String {
        switch self {
        case .due:
            return rmbLocalized(.upcomingRemindersDueFilterOption)
        case .today:
            return rmbLocalized(.upcomingRemindersTodayFilterOption)
        case .week:
            return rmbLocalized(.upcomingRemindersInAWeekFilterOption)
        case .month:
            return rmbLocalized(.upcomingRemindersInAMonthFilterOption)
        case .all:
            return rmbLocalized(.upcomingRemindersAllFilterOption)
        }
    }

    var endingDate: Date? {
        switch self {
        case .due:
            return Date()
        case .today:
            return Calendar.current.endOfDay(for: Date())
        case .week:
            return Calendar.current.date(byAdding: .weekOfMonth, value: 1, to: Date())
        case .month:
            return Calendar.current.date(byAdding: .month, value: 1, to: Date())
        case .all:
            return .distantFuture
        }
    }
}
