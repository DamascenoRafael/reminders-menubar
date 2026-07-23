import EventKit

struct RmbReminder {
    private var originalReminder: EKReminder?
    private var isPreparingToSave = false

    private struct DateTimeFallback {
        let hasDueDate: Bool
        let hasTime: Bool
        let date: Date
    }

    private var dateTimeFallback: DateTimeFallback?
    private var calendarFallback: EKCalendar?

    // MARK: - Change detection

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

    // MARK: - Properties

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
    private(set) var date: Date
    private(set) var hasDueDate: Bool
    private(set) var hasTime: Bool
    var recurrence: RmbRecurrenceOption
    var priority: EKReminderPriority
    var isFlagged: Bool
    private(set) var isUrgent: Bool
    private(set) var tags: [Tag]
    private(set) var calendar: EKCalendar?
    
    private var textDateResult = DateParser.TextDateResult()
    private var textCalendarResult = CalendarParser.TextCalendarResult()
    private var textPriorityResult = PriorityParser.PriorityParserResult()
    private var textTagResults: [TagParser.TextTagResult] = []
    
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
        calendarFallback = reminder.calendar
        tags = []
        if #available(macOS 12, *) {
            tags = reminder.ekTags
        }

        defer {
            // NOTE: defer ensures updateDateTimeFallback() runs after all stored properties are initialized.
            updateDateTimeFallback()
        }
    }

    // MARK: - User-intent mutations

    mutating func userDidSetDate(_ newDate: Date) {
        date = newDate
        textDateResult = DateParser.TextDateResult()
        updateDateTimeFallback()
    }

    mutating func userDidSetHasDueDate(_ enabled: Bool) {
        hasDueDate = enabled
        if !enabled {
            hasTime = false
            recurrence = .none
            isUrgent = false
            textDateResult = DateParser.TextDateResult()
        }
        updateDateTimeFallback()
    }

    mutating func userDidSetHasTime(_ enabled: Bool) {
        hasTime = enabled
        if enabled {
            date = .nextExactHour(of: date)
            hasDueDate = true
        } else {
            isUrgent = false
        }
        updateDateTimeFallback()
    }

    mutating func userDidSetIsUrgent(_ enabled: Bool) {
        isUrgent = enabled
        // NOTE: Urgent requires date+time.
        if enabled && !hasTime {
            date = .nextExactHour(of: date)
            hasDueDate = true
            hasTime = true
            updateDateTimeFallback()
        }
    }

    mutating func userDidSetCalendar(_ newCalendar: EKCalendar) {
        calendar = newCalendar
        calendarFallback = newCalendar
        let parsedCalendarIdentifier = textCalendarResult.calendar?.calendarIdentifier
        if newCalendar.calendarIdentifier != parsedCalendarIdentifier {
            textCalendarResult = CalendarParser.TextCalendarResult()
        }
    }

    mutating func setIsAutoSuggestingTodayForCreation() {
        hasDueDate = true
        updateDateTimeFallback()
    }

    func titleRemovingParsedTokens() -> String {
        var title = self.title

        if let parsedPriorityRange = Range(textPriorityResult.highlightedText.range, in: title) {
            title.replaceSubrange(parsedPriorityRange, with: "")
        }
        title = title.replacingOccurrences(of: textDateResult.string, with: "")
        title = title.replacingOccurrences(of: textCalendarResult.string, with: "")
        for tagResult in textTagResults.sorted(by: { $0.string.count > $1.string.count }) {
            title = title.replacingOccurrences(of: tagResult.string, with: "")
        }

        return title.trimmingCharacters(in: .whitespaces)
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

    private mutating func updateDateTimeFallback() {
        if !hasDueDate && !hasTime {
            dateTimeFallback = nil
        } else {
            dateTimeFallback = DateTimeFallback(hasDueDate: hasDueDate, hasTime: hasTime, date: date)
        }
    }

    // MARK: - Text parsing

    private mutating func updateTextDateResult(with newTitle: String) {
        guard let dateResult = DateParser.shared.getDate(from: newTitle) else {
            // NOTE: If there was a previous parse result, revert to the fallback state.
            if !textDateResult.string.isEmpty {
                revertToDateTimeFallback()
                textDateResult = DateParser.TextDateResult()
            }
            return
        }
        
        hasDueDate = true
        if dateResult.hasDate && dateResult.hasTime {
            hasTime = true
            date = dateResult.date
        } else if dateResult.hasDate {
            // NOTE: Parser found date-only (e.g. "tomorrow"). Check fallback for time.
            if dateTimeFallback?.hasTime == true, let fallbackDate = dateTimeFallback?.date {
                hasTime = true
                date = dateResult.date.withTime(from: fallbackDate)
            } else {
                hasTime = false
                isUrgent = false
                date = dateResult.date
            }
        } else if dateResult.hasTime {
            // NOTE: Parser found time-only (e.g. "9pm"). Check fallback for date.
            hasTime = true
            if dateTimeFallback?.hasDueDate == true, let fallbackDate = dateTimeFallback?.date {
                date = fallbackDate.withTime(from: dateResult.date)
            } else {
                date = dateResult.date
            }
        }

        textDateResult = dateResult.textDateResult
    }
    
    private mutating func revertToDateTimeFallback() {
        if let fallback = dateTimeFallback {
            hasDueDate = fallback.hasDueDate
            hasTime = fallback.hasTime
            date = fallback.date
            // NOTE: Enforce consistency for properties not stored in the fallback.
            if !fallback.hasDueDate {
                recurrence = .none
                isUrgent = false
            } else if !fallback.hasTime {
                isUrgent = false
            }
        } else {
            hasDueDate = false
            hasTime = false
            date = .nextExactHour()
            recurrence = .none
            isUrgent = false
        }
    }

    private mutating func updateTextCalendarResult(with newTitle: String) {
        guard let calendarResult = CalendarParser.getCalendar(from: newTitle) else {
            // NOTE: If there was a previous parse result, revert to the fallback state.
            if !textCalendarResult.string.isEmpty, let fallback = calendarFallback {
                calendar = fallback
            }
            textCalendarResult = CalendarParser.TextCalendarResult()
            return
        }
        calendar = calendarResult.calendar
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
