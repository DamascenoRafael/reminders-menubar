import EventKit

@MainActor
class RemindersService {
    static let shared = RemindersService()
    
    private init() {
        // This prevents others from using the default '()' initializer for this class.
    }
    
    private lazy var eventStore: EKEventStore? = {
        guard AppConstants.useNativeReminders else { return nil }
        return EKEventStore()
    }()

    func authorizationStatus() -> EKAuthorizationStatus {
        guard AppConstants.useNativeReminders else {
            if #available(macOS 14.0, *) {
                return .fullAccess
            } else {
                return .authorized
            }
        }
        return EKEventStore.authorizationStatus(for: .reminder)
    }

    // macOS 14 introduced distinct fullAccess/writeOnly statuses for Reminders.
    // This helper reflects whether the app has the read/write access it needs.
    func hasFullRemindersAccess() -> Bool {
        guard AppConstants.useNativeReminders else {
            return true
        }
        let status = EKEventStore.authorizationStatus(for: .reminder)
        if #available(macOS 14.0, *) {
            switch status {
            case .fullAccess:
                return true
            case .authorized:
                // Some macOS 14 builds still surface the legacy .authorized state.
                return true
            default:
                return false
            }
        } else {
            return status == .authorized
        }
    }
    
    func requestAccess(completion: @escaping (Bool, String?) -> Void) {
        guard AppConstants.useNativeReminders else {
            completion(true, nil)
            return
        }
        if #available(macOS 14.0, *) {
            eventStore?.requestFullAccessToReminders { granted, error in
                completion(granted, error?.localizedDescription)
            }
        } else {
            eventStore?.requestAccess(to: .reminder) { granted, error in
                completion(granted, error?.localizedDescription)
            }
        }
    }
    
    func getCalendar(withIdentifier calendarIdentifier: String) -> EKCalendar? {
        guard let eventStore else {
            return nil
        }
        return eventStore.calendar(withIdentifier: calendarIdentifier)
    }
    
    func getCalendars() -> [EKCalendar] {
        guard let eventStore else {
            return []
        }
        return eventStore.calendars(for: .reminder)
    }
    
    func getDefaultCalendar() -> EKCalendar? {
        guard let eventStore else {
            return nil
        }
        return eventStore.defaultCalendarForNewReminders() ?? eventStore.calendars(for: .reminder).first
    }

    func ensureCalendar(named title: String) -> EKCalendar? {
        guard let eventStore else {
            return nil
        }
        // Try existing
        if let existing = getCalendars().first(where: { $0.title.caseInsensitiveCompare(title) == .orderedSame }) {
            return existing
        }
        // Create a new calendar under the default source
        guard let base = getDefaultCalendar() else { return nil }
        let cal = EKCalendar(for: .reminder, eventStore: eventStore)
        cal.title = title
        cal.source = base.source
        do {
            try eventStore.saveCalendar(cal, commit: true)
            return cal
        } catch {
            print("Error creating calendar:", error.localizedDescription)
            return nil
        }
    }

    func move(reminder: EKReminder, to calendar: EKCalendar) {
        reminder.calendar = calendar
        save(reminder: reminder)
    }

    private func fetchReminders(matching predicate: NSPredicate) async -> [EKReminder] {
        guard let eventStore else {
            return []
        }
        return await withCheckedContinuation { continuation in
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
        guard let eventStore else {
            return []
        }
        let calendars = getCalendars().filter({ calendarIdentifiers.contains($0.calendarIdentifier) })
        let predicate = eventStore.predicateForReminders(in: calendars)
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
    
    func getUpcomingReminders(
        _ interval: ReminderInterval,
        for calendarIdentifiers: [String]? = nil
    ) async -> [ReminderItem] {
        guard let eventStore else {
            return []
        }
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
        return reminders.sortedReminders
    }
    
    func save(reminder: EKReminder) {
        guard let eventStore else {
            return
        }
        do {
            try eventStore.save(reminder, commit: true)
        } catch {
            print("Error saving reminder:", error.localizedDescription)
        }
    }
    
    @discardableResult
    func createNew(with rmbReminder: RmbReminder, in calendar: EKCalendar) -> EKReminder? {
        guard let eventStore else {
            return nil
        }
        let newReminder = EKReminder(eventStore: eventStore)
        newReminder.update(with: rmbReminder)
        newReminder.calendar = calendar
        do {
            try eventStore.save(newReminder, commit: true)
            return newReminder
        } catch {
            print("Error saving reminder:", error.localizedDescription)
            return nil
        }
    }
    
    func remove(reminder: EKReminder) {
        guard let eventStore else {
            return
        }
        do {
            try eventStore.remove(reminder, commit: true)
        } catch {
            print("Error removing reminder:", error.localizedDescription)
        }
    }
}
