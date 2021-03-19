import Foundation

enum ReminderInterval: String, Codable, CaseIterable {
    case today = "Today"
    case week = "In a Week"
    case month = "In a Month"
    case all = "All"
    
    var endingDate: Date? {
        switch self {
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
