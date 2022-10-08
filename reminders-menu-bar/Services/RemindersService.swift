import EventKit

class RemindersService {
    static let instance = RemindersService()
    
    private init() {
        // This prevents others from using the default '()' initializer for this class.
    }
    
    private let eventStore = EKEventStore()
    
    func authorizationStatus() -> EKAuthorizationStatus {
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
    
    func isValid(calendarIdentifier: String) -> Bool {
        return eventStore.calendar(withIdentifier: calendarIdentifier) != nil
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
            guard let allReminders = allReminders else {
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

    func getReminders(of calendarIdentifiers: [String]) -> [ReminderList] {
        let calendars = getCalendars().filter({ calendarIdentifiers.contains($0.calendarIdentifier) })
        let predicate = eventStore.predicateForReminders(in: calendars)
        
        let allReminders = fetchRemindersSynchronously(matching: predicate)
        var remindersStore: [ReminderList] = []
        
        for calendar in calendars {
            let reminders = allReminders.filter({
                $0.calendar.calendarIdentifier == calendar.calendarIdentifier
            })
            remindersStore.append(ReminderList(for: calendar, with: reminders))
        }
        
        return remindersStore
    }
    
    func getUpcomingReminders(_ interval: ReminderInterval) -> [EKReminder] {
        let calendars = getCalendars()
        let predicate = eventStore.predicateForIncompleteReminders(withDueDateStarting: nil,
                                                                   ending: interval.endingDate,
                                                                   calendars: calendars)
        
        let reminders = fetchRemindersSynchronously(matching: predicate)
        return reminders.sortedReminders
    }
    
    func save(reminder: EKReminder) {
        do {
            try eventStore.save(reminder, commit: true)
        } catch {
            print("Error saving reminder:", error.localizedDescription)
        }
    }
    
    func createNew(with title: String, in calendar: EKCalendar, deadline: Date?, hasDueDate: Bool, hasDueTime: Bool) {
        let newReminder = EKReminder(eventStore: eventStore)
        newReminder.title = title
        newReminder.calendar = calendar
        if let deadline = deadline{
            if hasDueDate {
                if hasDueTime {
                    newReminder.dueDateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: deadline)
                } else {
                    newReminder.dueDateComponents = Calendar.current.dateComponents([.year, .month, .day], from: deadline)
                }
            }
        }
        save(reminder: newReminder)
    }
    
    func remove(reminder: EKReminder) {
        // TODO: Commit changes while removing the reminder
        // Ideally, this function should commit changes directly.
        // But this ends up generating unexpected behavior in ReminderItemView.
        do {
            try eventStore.remove(reminder, commit: false)
        } catch {
            print("Error removing reminder:", error.localizedDescription)
        }
        
        NotificationCenter.default.post(name: .EKEventStoreChanged, object: nil)
    }
    
    func commitChanges() {
        do {
            try eventStore.commit()
        } catch {
            print("Error commiting changes:", error.localizedDescription)
        }
    }
}
