import Foundation
import EventKit

struct RmbReminder {
    var title: String
    var notes: String?
    var date: Date
    var hasDueDate: Bool {
        didSet {
            // NOTE: When the hasDueDate option is disabled, it must disable hasTime
            // so that, if enabled again, it does not have "remind me at a time" enabled
            if !hasDueDate {
                hasTime = false
            }
        }
    }
    var hasTime: Bool {
        didSet {
            // NOTE: When enabling the option to add a time the suggestion will be the next hour of the current moment
            date = Date.currentNextHour(of: date)
        }
    }
    var priority: EKReminderPriority

    init() {
        title = ""
        date = .currentNextHour()
        hasDueDate = false
        hasTime = false
        priority = .none
    }
    
    init(reminder: EKReminder) {
        title = reminder.title
        notes = reminder.notes
        date = reminder.dueDateComponents?.date ?? .currentNextHour()
        hasDueDate = reminder.hasDueDate
        hasTime = reminder.hasTime
        priority = reminder.ekPriority
    }
}
