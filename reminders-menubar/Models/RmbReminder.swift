import EventKit

struct RmbReminder {
    private var originalReminder: EKReminder?
    private var isPreparingToSave = false
    
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
    
    var title: String {
        willSet {
            if isPreparingToSave {
                return
            }
            updateTextDateResult(with: newValue)
            updateTextCalendarResult(with: newValue)
        }
    }
    
    var notes: String?
    var date: Date {
        didSet {
            // NOTE: When the date is changed, we assume that it was done by the user.
            // If it was changed by DateParser it is necessary to add textDateResult after changing the date.
            textDateResult = DateParser.TextDateResult()
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
    
    var textDateResult = DateParser.TextDateResult()
    var textCalendarResult = CalendarParser.TextCalendarResult()
    
    var highlightedTexts: [RmbHighlightedTextField.HighlightedText] {
        [textDateResult.highlightedText, textCalendarResult.highlightedText]
    }

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
    
    mutating func prepareToSave() {
        isPreparingToSave = true
    }
    
    private mutating func updateTextDateResult(with newTitle: String) {
        // NOTE: If a date was defined by the user then the DateParser should not be applied.
        if hasDueDate && textDateResult.string.isEmpty {
            return
        }
        
        guard let dateResult = DateParser.shared.getDate(from: newTitle) else {
            hasDueDate = false
            hasTime = false
            date = .nextHour()
            textDateResult = DateParser.TextDateResult()
            return
        }
        
        hasDueDate = true
        hasTime = dateResult.hasTime
        date = dateResult.date
        textDateResult = dateResult.textDateResult
    }
    
    private mutating func updateTextCalendarResult(with newTitle: String) {
        guard let calendarResult = CalendarParser.getCalendar(from: newTitle) else {
            textCalendarResult = CalendarParser.TextCalendarResult()
            return
        }
        
        textCalendarResult = calendarResult
    }
}
