import EventKit

class RemindersService {
    static let instance = RemindersService()
    
    let eventStore = EKEventStore()
    
    private init() {
        // This prevents others from using the default '()' initializer for this class.
    }
    
    func hasAuthorization() -> EKAuthorizationStatus  {
        return EKEventStore.authorizationStatus(for: .reminder)
    }
    
    func requestAccess() {
        eventStore.requestAccess(to: .reminder) { (granted, error) in
            guard granted else {
                print("Access to store not granted:")
                print(error ?? "no error")
                return
            }
        }
    }
    
    func getDefaultCalendar() -> EKCalendar {
        return eventStore.defaultCalendarForNewReminders()!
    }
    
    func getCalendars() -> [EKCalendar] {
        guard let source = eventStore.sources.first else {
            return []
        }
        
        let calendars = source.calendars(for: .reminder)
        return Array(calendars)
    }
    
    func getReminders() -> [ReminderList] {
        let group = DispatchGroup()
        
        var remindersStore: [ReminderList] = []
        if let source = eventStore.sources.first {
            let reminderLists = source.calendars(for: .reminder)
            for reminderList in reminderLists {
                group.enter()
                
                let predicate = eventStore.predicateForReminders(in: [reminderList])
                eventStore.fetchReminders(matching: predicate) { (reminders) in
                    guard let reminders = reminders else {
                        print("reminders was nil")
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
            try self.eventStore.save(reminder, commit: true)
        } catch {
            print("Erro saving reminder:", error)
        }
    }
    
    func createNew(with title: String, in calendar: EKCalendar) {
        let newReminder = EKReminder(eventStore: eventStore)
        newReminder.title = title
        newReminder.calendar = calendar
        self.save(reminder: newReminder)
    }
    
    func remove(reminder: EKReminder) {
        do {
            try eventStore.remove(reminder, commit: true)
        } catch {
            print("Erro removing reminder:", error)
        }
    }
}
