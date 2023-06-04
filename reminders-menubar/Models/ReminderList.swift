import EventKit
import AppKit

struct ReminderList: Identifiable {
    let id: String
    let calendar: EKCalendar
    let completedReminders: [EKReminder]
    let uncompletedReminders: [EKReminder]
    
    init(for calendar: EKCalendar, with reminders: [EKReminder]) {
        self.id = calendar.calendarIdentifier
        self.calendar = calendar
        (self.completedReminders, self.uncompletedReminders) = ReminderList.labeledReminders(reminders)
    }
    
    private static func labeledReminders(
        _ reminders: [EKReminder]
    ) -> (completed: [EKReminder], notCompleted: [EKReminder]) {
        var (completedReminders, uncompletedReminders) = reminders.separeted(by: { $0.isCompleted })
        
        completedReminders = completedReminders.sortedRemindersByPriority
        uncompletedReminders = uncompletedReminders.sortedRemindersByPriority
        
        return (completedReminders, uncompletedReminders)
    }
}
