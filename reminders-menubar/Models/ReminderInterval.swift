import Foundation

enum ReminderInterval: String, Codable, CaseIterable {
    case due
    case today
    case week
    case month
    case all
    
    var title: String {
        switch self {
        case .due:
            return rmbLocalized(.upcomingRemindersDueTitle)
        case .today:
            return rmbLocalized(.upcomingRemindersTodayTitle)
        case .week:
            return rmbLocalized(.upcomingRemindersInAWeekTitle)
        case .month:
            return rmbLocalized(.upcomingRemindersInAMonthTitle)
        case .all:
            return rmbLocalized(.upcomingRemindersAllTitle)
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
            return Date.distantFuture
        }
    }
}
