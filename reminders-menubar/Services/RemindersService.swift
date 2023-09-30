import EventKit

class RemindersService {
    static let shared = RemindersService()
    
    private init() {
        // This prevents others from using the default '()' initializer for this class.
    }
    
    private let eventStore = EKEventStore()
    
    func authorizationStatus() -> EKAuthorizationStatus {
        return EKEventStore.authorizationStatus(for: .reminder)
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
    
    func getDefaultCalendar() -> EKCalendar {
        return eventStore.defaultCalendarForNewReminders() ?? eventStore.calendars(for: .reminder).first!
    }
    
    private func fetchRemindersSynchronously(matching predicate: NSPredicate) -> [EKReminder] {
        var reminders: [EKReminder] = []
        // TODO: Remove use of DispatchGroup
        let group = DispatchGroup()
        group.enter()
        eventStore.fetchReminders(matching: predicate) { allReminders in
            guard let allReminders else {
                print("Reminders was nil during 'fetchReminders'")
                group.leave()
                return
            }
            
            reminders = allReminders
            group.leave()
        }
        
        _ = group.wait(timeout: .distantFuture)
        
        return reminders
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

    func getReminders(of calendarIdentifiers: [String]) -> [ReminderList] {
        let calendars = getCalendars().filter({ calendarIdentifiers.contains($0.calendarIdentifier) })
        let predicate = eventStore.predicateForReminders(in: calendars)
        let remindersByCalendar = Dictionary(grouping: fetchRemindersSynchronously(matching: predicate),
                                             by: { $0.calendar.calendarIdentifier })
        
        var reminderLists: [ReminderList] = []
        for calendar in calendars {
            let calendarReminders = remindersByCalendar[calendar.calendarIdentifier, default: []]
            let reminderListItems = createReminderItems(for: calendarReminders)
            reminderLists.append(ReminderList(for: calendar, with: reminderListItems))
        }
        
        return reminderLists
    }
    
    func getUpcomingReminders(_ interval: ReminderInterval) -> [ReminderItem] {
        let calendars = getCalendars()
        let predicate = eventStore.predicateForIncompleteReminders(withDueDateStarting: nil,
                                                                   ending: interval.endingDate,
                                                                   calendars: calendars)
        let reminders = fetchRemindersSynchronously(matching: predicate).map({ ReminderItem(for: $0) })
        return reminders.sortedReminders
    }
    
    func getAllRemindersCount() -> Int {
        let predicate = eventStore.predicateForIncompleteReminders(withDueDateStarting: nil,
                                                                   ending: nil,
                                                                   calendars: nil)
        let reminders = fetchRemindersSynchronously(matching: predicate)
        return reminders.count
    }
    
    func save(reminder: EKReminder) {
        do {
            try eventStore.save(reminder, commit: true)
        } catch {
            print("Error saving reminder:", error.localizedDescription)
        }
    }
    
    func createNew(with rmbReminder: RmbReminder, in calendar: EKCalendar) {
        let newReminder = EKReminder(eventStore: eventStore)
        newReminder.update(with: rmbReminder)
        newReminder.calendar = calendar
        save(reminder: newReminder)
    }
    
    func remove(reminder: EKReminder) {
        do {
            try eventStore.remove(reminder, commit: true)
        } catch {
            print("Error removing reminder:", error.localizedDescription)
        }
    }
}
