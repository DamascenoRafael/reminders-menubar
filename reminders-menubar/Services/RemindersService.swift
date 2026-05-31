import EventKit

@MainActor
class RemindersService {
    static let shared = RemindersService()
    
    private init() {
        // This prevents others from using the default '()' initializer for this class.
    }
    
    private let eventStore = EKEventStore()
    
    var isAuthorized: Bool {
        if #available(macOS 14.0, *) {
            return EKEventStore.authorizationStatus(for: .reminder) == .fullAccess
        } else {
            return EKEventStore.authorizationStatus(for: .reminder) == .authorized
        }
    }
    
    func requestAccess(completion: @escaping (Bool, String?) -> Void) {
        if #available(macOS 14.0, *) {
            eventStore.requestFullAccessToReminders { granted, error in
                completion(granted, error?.localizedDescription)
            }
        } else {
            eventStore.requestAccess(to: .reminder) { granted, error in
                completion(granted, error?.localizedDescription)
            }
        }
    }
    
    func getCalendar(withIdentifier calendarIdentifier: String) -> EKCalendar? {
        return eventStore.calendar(withIdentifier: calendarIdentifier)
    }
    
    func getCalendars() -> [EKCalendar] {
        return eventStore.calendars(for: .reminder)
    }
    
    func getDefaultCalendar() -> EKCalendar? {
        return eventStore.defaultCalendarForNewReminders() ?? eventStore.calendars(for: .reminder).first
    }
    
    private func fetchReminders(matching predicate: NSPredicate) async -> [EKReminder] {
        await withCheckedContinuation { continuation in
            eventStore.fetchReminders(matching: predicate) { allReminders in
                guard let allReminders else {
                    continuation.resume(returning: [])
                    return
                }
                continuation.resume(returning: allReminders)
            }
        }
    }

    private func createReminderItems(for calendarReminders: [EKReminder]) -> [ReminderItem] {
        var reminderListItems: [ReminderItem] = []
        
        let noParentKey = "noParentKey"
        let remindersByParentId = Dictionary(grouping: calendarReminders, by: { $0.parentId ?? noParentKey })
        let parentReminders = remindersByParentId[noParentKey, default: []]
        
        parentReminders.forEach { parentReminder in
            let parentId = parentReminder.calendarItemIdentifier
            let children = remindersByParentId[parentId, default: []].map({ ReminderItem(for: $0, isChild: true) })
            reminderListItems.append(ReminderItem(for: parentReminder, withChildren: children))
        }
        return reminderListItems
    }

    func getReminders(of calendarIdentifiers: [String]) async -> [ReminderList] {
        let calendars = getCalendars().filter({ calendarIdentifiers.contains($0.calendarIdentifier) })
        let predicate = eventStore.predicateForIncompleteReminders(
            withDueDateStarting: nil,
            ending: nil,
            calendars: calendars
        )
        let remindersByCalendar = Dictionary(
            grouping: await fetchReminders(matching: predicate),
            by: { $0.calendar.calendarIdentifier }
        )

        var reminderLists: [ReminderList] = []
        for calendar in calendars {
            let calendarReminders = remindersByCalendar[calendar.calendarIdentifier, default: []]
            let reminderListItems = createReminderItems(for: calendarReminders)
            reminderLists.append(ReminderList(for: calendar, with: reminderListItems))
        }
        
        return reminderLists
    }

    func getRecentReminders() async -> [ReminderItem] {
        let recentRemindersDayCount = 90
        let predicate = eventStore.predicateForReminders(in: nil)
        let cutoffDate = Calendar.current.date(
            byAdding: .day,
            value: -recentRemindersDayCount,
            to: Date()
        ) ?? Date.distantPast

        let allReminders = await fetchReminders(matching: predicate)
        let recentReminders = allReminders
            .filter { ($0.lastModifiedDate ?? .distantPast) >= cutoffDate }

        return recentReminders
            .map { ReminderItem(for: $0) }
            .sorted { ($0.lastModifiedDate ?? .distantPast) > ($1.lastModifiedDate ?? .distantPast) }
    }
    
    func getUpcomingReminders(
        _ interval: ReminderInterval,
        for calendarIdentifiers: [String]? = nil
    ) async -> [ReminderItem] {
        var calendars: [EKCalendar]?
        if let calendarIdentifiers {
            if calendarIdentifiers.isEmpty {
                // If the filter does not have any calendar selected, return empty
                return []
            }
            calendars = getCalendars().filter({ calendarIdentifiers.contains($0.calendarIdentifier) })
        }
        let predicate = eventStore.predicateForIncompleteReminders(
            withDueDateStarting: nil,
            ending: interval.endingDate,
            calendars: calendars
        )
        var reminders = await fetchReminders(matching: predicate).map({ ReminderItem(for: $0) })
        if interval == .due {
            // For the 'due' interval, we should filter reminders for today with no time.
            // These will only be considered due/expired on the following day.
            reminders = reminders.filter { $0.reminder.isExpired }
        }
        return reminders.sortedUpcomingReminders
    }
    
    func save(reminder: EKReminder, tags: [Tag]? = nil) {
        do {
            try eventStore.save(reminder, commit: true)
            // NOTE: Tags are persisted via REMSaveRequest directly.
            if #available(macOS 12, *), let tags {
                reminder.updateTags(tags)
            }
        } catch {
            print("Error saving reminder:", error.localizedDescription)
        }
    }
    
    func createNew(with rmbReminder: RmbReminder, in calendar: EKCalendar) {
        let newReminder = EKReminder(eventStore: eventStore)
        newReminder.update(with: rmbReminder)
        newReminder.calendar = calendar
        save(reminder: newReminder, tags: rmbReminder.tags)
    }
    
    func fetchAllReminders() async -> [EKReminder] {
        let predicate = eventStore.predicateForReminders(in: nil)
        return await fetchReminders(matching: predicate)
    }

    func getAllTags() async -> [Tag] {
        guard #available(macOS 12, *) else { return [] }

        let allReminders = await fetchAllReminders()
        var tags: Set<Tag> = []
        for reminder in allReminders {
            for tag in reminder.ekTags {
                tags.insert(tag)
            }
        }
        return tags.sorted()
    }

    @available(macOS 12, *)
    func getReminders(byTags tags: [Tag], calendarIdentifiers: [String]?) async -> [TagReminderList] {
        guard !tags.isEmpty else { return [] }

        var calendars: [EKCalendar]?
        if let calendarIdentifiers {
            if calendarIdentifiers.isEmpty {
                return []
            }
            calendars = getCalendars().filter({ calendarIdentifiers.contains($0.calendarIdentifier) })
        }

        let predicate = eventStore.predicateForIncompleteReminders(
            withDueDateStarting: nil,
            ending: nil,
            calendars: calendars
        )
        let allReminders = await fetchReminders(matching: predicate)

        var tagReminderLists: [TagReminderList] = []

        for tag in tags {
            let matchingReminders = allReminders.filter { reminder in
                reminder.ekTags.contains(tag)
            }
            let reminderItems = createReminderItems(for: matchingReminders)
            tagReminderLists.append(TagReminderList(for: tag, with: reminderItems))
        }

        return tagReminderLists
    }

    func searchReminders(matching query: String, in allReminders: [EKReminder]) -> [ReminderItem] {
        let queryWords = query
            .lowercased()
            .split(separator: " ")
            .map { (word: String($0), tagWord: $0.hasPrefix("#") ? String($0.dropFirst()) : nil) }
        guard !queryWords.isEmpty else { return [] }

        let scored: [(ReminderItem, Int)] = allReminders.compactMap { reminder in
            let title = (reminder.title ?? "").lowercased()
            let notes = (reminder.notes ?? "").lowercased()
            let urlString = reminder.attachedUrl?.absoluteString.lowercased() ?? ""
            var tagNames: [String] = []
            if #available(macOS 12, *) {
                tagNames = reminder.ekTags.map({ $0.name.lowercased() })
            }

            let allFields = [title, notes, urlString] + tagNames

            let allWordsMatch = queryWords.allSatisfy { word, tagWord in
                if let tagWord, !tagWord.isEmpty,
                   tagNames.contains(where: { $0.contains(tagWord) }) {
                    return true
                }
                return allFields.contains { $0.contains(word) }
            }
            guard allWordsMatch else { return nil }

            var score = 0
            for (word, tagWord) in queryWords {
                if title.contains(word) { score += 3 }
                if notes.contains(word) { score += 2 }
                if tagNames.contains(where: { $0.contains(tagWord ?? word) }) { score += 2 }
                if urlString.contains(word) { score += 1 }
            }
            if !reminder.isCompleted { score += 1 }

            return (ReminderItem(for: reminder), score)
        }

        return scored
            .sorted { $0.1 > $1.1 }
            .map { $0.0 }
    }

    func remove(reminder: EKReminder) {
        do {
            try eventStore.remove(reminder, commit: true)
        } catch {
            print("Error removing reminder:", error.localizedDescription)
        }
    }
}
