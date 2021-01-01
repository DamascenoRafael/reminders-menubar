import EventKit

class RemindersService {
    static let instance = RemindersService()
    
    let eventStore = EKEventStore()
    
    private init() {
        // This prevents others from using the default '()' initializer for this class.
    }
    
    func hasAuthorization() -> EKAuthorizationStatus {
        return EKEventStore.authorizationStatus(for: .reminder)
    }
    
    func requestAccess() {
        eventStore.requestAccess(to: .reminder) { granted, error in
            guard granted else {
                let errorDescription = error?.localizedDescription ?? "no error description"
                print("Access to store not granted:", errorDescription)
                return
            }
        }
    }
    
    func getDefaultCalendar() -> EKCalendar {
        return eventStore.defaultCalendarForNewReminders() ?? eventStore.calendars(for: .reminder).first!
    }
    
    func getCalendars() -> [EKCalendar] {
        return eventStore.calendars(for: .reminder).sorted(by: { $0.title.compare($1.title) == .orderedAscending })
    }
    
    func getReminders(of calendarIdentifiers: [String]) -> [ReminderList] {
        let group = DispatchGroup()
        
        var remindersStore: [ReminderList] = []
        if let source = eventStore.sources.first {
            let reminderLists = source.calendars(for: .reminder)
            for reminderList in reminderLists {
                guard calendarIdentifiers.contains(reminderList.calendarIdentifier) else { continue }
                
                group.enter()
                
                let predicate = eventStore.predicateForReminders(in: [reminderList])
                eventStore.fetchReminders(matching: predicate) { reminders in
                    guard let reminders = reminders else {
                        print("Reminders was nil during 'fetchReminders'")
                        return
                    }
                    
                    remindersStore.append(ReminderList(for: reminderList, with: reminders))
                    group.leave()
                }
            }
        }
        
        _ = group.wait(timeout: .distantFuture)
        return remindersStore
    }
    
    func save(reminder: EKReminder) {
        do {
            try eventStore.save(reminder, commit: true)
        } catch {
            print("Error saving reminder:", error.localizedDescription)
        }
    }
    
    func createNew(with title: String, in calendar: EKCalendar) {
        let newReminder = EKReminder(eventStore: eventStore)
        newReminder.title = title
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
