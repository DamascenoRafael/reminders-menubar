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
    
    func createNew(with title: String) {
        let newReminder = EKReminder(eventStore: eventStore)
        newReminder.title = title
        newReminder.calendar = eventStore.defaultCalendarForNewReminders()
        self.save(reminder: newReminder)
    }
}
