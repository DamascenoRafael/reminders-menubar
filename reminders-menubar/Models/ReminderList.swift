import EventKit
import AppKit

struct ReminderList: Identifiable {
    let id: String
    let calendar: EKCalendar
    let reminders: [EKReminder]
    
    init(for calendar: EKCalendar, with reminders: [EKReminder]) {
        self.id = calendar.calendarIdentifier
        self.calendar = calendar
        self.reminders = reminders
    }
}
