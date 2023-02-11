import Foundation
import EventKit

struct RmbReminder {
    private var originalReminder: EKReminder?
    
    var hasDateChanges: Bool {
        guard let originalReminder else {
            return true
        }
        
        let hasChanges =
            hasDueDate != originalReminder.hasDueDate ||
            hasTime != originalReminder.hasTime ||
            date != originalReminder.dueDateComponents?.date
        return hasChanges
    }
    
    var title: String
    var dateRelatedText: String
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
            date = .nextHour(of: date)
        }
    }
    var priority: EKReminderPriority

    init() {
        title = ""
        dateRelatedText = ""
        date = .nextHour()
        hasDueDate = false
        hasTime = false
        priority = .none
    }
    
    init(reminder: EKReminder) {
        originalReminder = reminder
        title = reminder.title
        dateRelatedText = ""
        notes = reminder.notes
        date = reminder.dueDateComponents?.date ?? .nextHour()
        hasDueDate = reminder.hasDueDate
        hasTime = reminder.hasTime
        priority = reminder.ekPriority
    }
}
