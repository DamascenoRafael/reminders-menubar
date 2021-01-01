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
        var remindersStore: [ReminderList] = []
        
        let calendars = getCalendars().filter({ calendarIdentifiers.contains($0.calendarIdentifier) })
        let predicate = eventStore.predicateForReminders(in: calendars)
        
        // TODO: Remove use of DispatchGroup
        let group = DispatchGroup()
        group.enter()
        eventStore.fetchReminders(matching: predicate) { allReminders in
            guard let allReminders = allReminders else {
                print("Reminders was nil during 'fetchReminders'")
                group.leave()
                return
            }
            
            for calendar in calendars {
                let reminders = allReminders.filter({
                    $0.calendar.calendarIdentifier == calendar.calendarIdentifier
                })
                
                remindersStore.append(ReminderList(for: calendar, with: reminders))
            }
            group.leave()
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
