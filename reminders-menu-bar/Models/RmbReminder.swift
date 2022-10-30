import Foundation
import EventKit

struct RmbReminder {
    var title: String
    var notes: String?
    var date: Date
    var hasDueDate: Bool
    var hasTime: Bool {
        didSet {
            // NOTE: When enabling the option to add a time the suggestion will be the next hour of the current moment
            date = Date.currentNextHour(of: date)
        }
    }
    var priority: EKReminderPriority
    
    init(reminder: EKReminder) {
        title = reminder.title
        notes = reminder.notes
        date = reminder.dueDateComponents?.date ?? Date.currentNextHour()
        hasDueDate = reminder.hasDueDate
        hasTime = reminder.hasTime
        priority = reminder.ekPriority
    }
}
