import EventKit
import AppKit

struct ReminderList: Identifiable {
    let id: String
    let title: String
    let color: NSColor
    let reminders: [EKReminder]
    
    init(for reminderList: EKCalendar, with reminders: [EKReminder]) {
        self.id = reminderList.calendarIdentifier
        self.title = reminderList.title
        self.color = reminderList.color
        self.reminders = reminders
    }
}
