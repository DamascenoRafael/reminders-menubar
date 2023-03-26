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
    var notes: String?
    var date: Date {
        didSet {
            // NOTE: When the date is changed, we assume that it was done by the user.
            // If it was changed by DateParser it is necessary to change dateRelatedString after changing the date.
            dateRelatedString = ""
        }
    }
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
    
    var dateRelatedString = ""

    init() {
        title = ""
        date = .nextHour()
        hasDueDate = false
        hasTime = false
        priority = .none
    }
    
    init(hasDueDate: Bool) {
        self.init()
        self.hasDueDate = hasDueDate
    }
    
    init(reminder: EKReminder) {
        originalReminder = reminder
        title = reminder.title
        notes = reminder.notes
        date = reminder.dueDateComponents?.date ?? .nextHour()
        hasDueDate = reminder.hasDueDate
        hasTime = reminder.hasTime
        priority = reminder.ekPriority
    }
    
    mutating func updateWithDateParser() {
        // NOTE: If a date was defined by the user then the DateParser should not be applied.
        if hasDueDate && dateRelatedString.isEmpty {
            return
        }
        
        guard let dateResult = DateParser.shared.getDate(from: title) else {
            hasDueDate = false
            hasTime = false
            date = .nextHour()
            dateRelatedString = ""
            return
        }
        
        hasDueDate = true
        hasTime = dateResult.hasTime
        date = dateResult.date
        dateRelatedString = dateResult.dateRelatedString
    }
}
