import EventKit

struct RmbReminder {
    private var originalReminder: EKReminder?
    private var isPreparingToSave = false
    private var isAutoSuggestingTodayForCreation = false
    
    var hasDateChanges: Bool {
        guard let originalReminder else {
            return true
        }
        
        return
            hasDueDate != originalReminder.hasDueDate ||
            hasTime != originalReminder.hasTime ||
            date != originalReminder.dueDateComponents?.date
    }
    
    var hasRecurrenceChanges: Bool {
        guard let originalReminder else {
            return recurrence != .none
        }
        
        return recurrence != RmbRecurrenceOption(from: originalReminder.recurrenceRules)
    }
    
    var hasTagChanges: Bool {
        guard let originalReminder else {
            return !tags.isEmpty
        }
        
        if #available(macOS 12, *) {
            return Set(tags) != Set(originalReminder.ekTags)
        }
        return false
    }

    var hasFlagChanges: Bool {
        guard let originalReminder else {
            return isFlagged
        }
        return isFlagged != originalReminder.isFlagged
    }

    var hasUrgentChanges: Bool {
        guard let originalReminder else {
            return isUrgent
        }

        if #available(macOS 26, *) {
            return isUrgent != originalReminder.isUrgent
        }
        return false
    }

    var hasPrivateApiChanges: Bool {
        hasTagChanges || hasFlagChanges || hasUrgentChanges
    }

    var title: String {
        willSet {
            guard !isPreparingToSave else {
                return
            }
            updateTextDateResult(with: newValue)
            updateTextCalendarResult(with: newValue)
            updateTextPriorityResult(with: newValue)
            if #available(macOS 12, *) {
                updateTextTagResults(with: newValue)
            }
        }
    }
    
    var notes: String?
    var date: Date {
        didSet {
            // NOTE: When date is changed, we assume that it was done by the user.
            // If it was changed by DateParser it is necessary to add textDateResult after changing the date.
            textDateResult = DateParser.TextDateResult()
            isAutoSuggestingTodayForCreation = false
        }
    }
    var hasDueDate: Bool {
        didSet {
            // NOTE: When hasDueDate option is disabled, it must disable hasTime and recurrence
            if !hasDueDate {
                hasTime = false
                recurrence = .none
                isUrgent = false
            }
        }
    }
    var hasTime: Bool {
        didSet {
            // NOTE: When hasTime option is enabled, adjust the suggestion to the next hour of the current moment.
            // Enabling time always requires a due date, so ensure it's turned on.
            if hasTime {
                date = .nextExactHour(of: date)
                hasDueDate = true
            } else {
                // NOTE: Urgent requires date+time, so disable it when time is removed.
                isUrgent = false
            }
        }
    }
    var recurrence: RmbRecurrenceOption
    var priority: EKReminderPriority
    var isFlagged: Bool
    var isUrgent: Bool {
        didSet {
            // NOTE: Urgent requires date+time, so enable them when urgent is turned on.
            if isUrgent {
                hasDueDate = true
                hasTime = true
            }
        }
    }
    private(set) var tags: [Tag]
    var calendar: EKCalendar?
    
    var textDateResult = DateParser.TextDateResult()
    var textCalendarResult = CalendarParser.TextCalendarResult()
    var textPriorityResult = PriorityParser.PriorityParserResult()
    var textTagResults: [TagParser.TextTagResult] = []
    
    var highlightedTexts: [RmbHighlightedTextField.HighlightedText] {
        var texts = [
            textDateResult.highlightedText,
            textCalendarResult.highlightedText,
            textPriorityResult.highlightedText
        ]
        texts.append(contentsOf: textTagResults.map({ $0.highlightedText }))
        return texts
    }

    init() {
        title = ""
        date = .nextExactHour()
        hasDueDate = false
        hasTime = false
        recurrence = .none
        priority = .none
        isFlagged = false
        isUrgent = false
        tags = []
    }
    
    init(reminder: EKReminder) {
        originalReminder = reminder
        title = reminder.title
        notes = reminder.notes
        date = reminder.dueDateComponents?.date ?? .nextExactHour()
        hasDueDate = reminder.hasDueDate
        hasTime = reminder.hasTime
        recurrence = RmbRecurrenceOption(from: reminder.recurrenceRules)
        priority = reminder.ekPriority
        isFlagged = reminder.isFlagged
        isUrgent = false
        if #available(macOS 26, *) {
            isUrgent = reminder.isUrgent
        }
        calendar = reminder.calendar
        tags = []
        if #available(macOS 12, *) {
            tags = reminder.ekTags
        }
    }

    mutating func setIsAutoSuggestingTodayForCreation() {
        guard !hasDueDate else {
            return
        }
        self.hasDueDate = true
        self.isAutoSuggestingTodayForCreation = true
    }

    mutating func prepareToSave() {
        isPreparingToSave = true
        textDateResult = DateParser.TextDateResult()
        textCalendarResult = CalendarParser.TextCalendarResult()
        textPriorityResult = PriorityParser.PriorityParserResult()
        textTagResults = []
    }

    mutating func addTag(named tagName: String) {
        let sanitizedTagName = TagParser.sanitizedTagName(tagName)
        guard !sanitizedTagName.isEmpty else {
            return
        }

        let resolvedTagName = TagParser.resolvedTagName(sanitizedTagName)
        let newTag = Tag(resolvedTagName)
        guard !tags.contains(newTag) else {
            return
        }

        tags.append(newTag)
    }

    mutating func removeTag(named tagName: String) {
        let tagToRemove = Tag(tagName)
        tags.removeAll(where: { $0 == tagToRemove })
        textTagResults.removeAll(where: { $0.tag == tagToRemove })
    }

    mutating func removeLastTag() {
        guard let lastTag = tags.last else {
            return
        }
        
        removeTag(named: lastTag.name)
    }
    
    private mutating func updateTextDateResult(with newTitle: String) {
        if isAutoSuggestingTodayForCreation {
            updateTextDateResultTimeOnly(with: newTitle, isAutoSuggestingToday: true)
            return
        }
        
        // NOTE: If a date was defined by the user then the DateParser should not be applied.
        if hasDueDate && textDateResult.string.isEmpty {
            return
        }
        
        guard let dateResult = DateParser.shared.getDate(from: newTitle) else {
            hasDueDate = false
            hasTime = false
            date = .nextExactHour()
            textDateResult = DateParser.TextDateResult()
            return
        }
        
        hasDueDate = true
        hasTime = dateResult.hasTime
        date = dateResult.date
        textDateResult = dateResult.textDateResult
    }
    
    private mutating func updateTextDateResultTimeOnly(with newTitle: String, isAutoSuggestingToday: Bool) {
        // NOTE: If a time was defined by the user then the DateParser should not be applied.
        if hasTime && textDateResult.string.isEmpty {
            return
        }
        
        guard let dateResult = DateParser.shared.getTimeOnly(from: newTitle, on: date) else {
            hasTime = false
            textDateResult = DateParser.TextDateResult()
            isAutoSuggestingTodayForCreation = isAutoSuggestingToday
            return
        }
        
        hasTime = true
        date = dateResult.date
        textDateResult = dateResult.textDateResult
        isAutoSuggestingTodayForCreation = isAutoSuggestingToday
    }
    
    private mutating func updateTextCalendarResult(with newTitle: String) {
        // NOTE: Unlike other properties, reminder calendar will not be overwritten by the parser.
        guard let calendarResult = CalendarParser.getCalendar(from: newTitle) else {
            textCalendarResult = CalendarParser.TextCalendarResult()
            return
        }
        textCalendarResult = calendarResult
    }
    
    private mutating func updateTextPriorityResult(with newTitle: String) {
        // NOTE: If a priority was defined by the user then the PriorityParser should not be applied.
        if priority != .none && textPriorityResult.string.isEmpty {
            return
        }
        
        guard let priorityResult = PriorityParser.getPriority(from: newTitle) else {
            textPriorityResult = PriorityParser.PriorityParserResult()
            priority = .none
            return
        }
        
        priority = priorityResult.priority
        textPriorityResult = priorityResult
    }
    
    @available(macOS 12, *)
    private mutating func updateTextTagResults(with newTitle: String) {
        let newTextTagResults = TagParser.getTags(from: newTitle)

        let newParsedTags = Set(newTextTagResults.map(\.tag))
        let previousParsedTags = Set(textTagResults.map(\.tag))

        let removedFromTitle = previousParsedTags.subtracting(newParsedTags)
        var addedFromTitle = newParsedTags.subtracting(tags)

        textTagResults = newTextTagResults

        // NOTE: Replace a renamed tag in-place to preserve the user's tag order.
        // Only triggers when exactly one tag was removed and one was added, ensuring it's genuinely a rename.
        if removedFromTitle.count == 1, addedFromTitle.count == 1,
           let newTag = addedFromTitle.first,
           let index = tags.firstIndex(where: { removedFromTitle.contains($0) }) {
            tags[index] = newTag
            addedFromTitle.removeFirst()
        }

        // NOTE: Remove any remaining tags that were parsed from the title but are no longer present.
        tags.removeAll(where: { removedFromTitle.contains($0) })

        // NOTE: Append any remaining new tags that are not yet in the tags array.
        for newTag in newParsedTags {
            addTag(named: newTag.name)
        }
    }
}
