import EventKit

struct ReminderList: Identifiable, Equatable {
    let id: String
    let calendar: EKCalendar
    let reminders: [ReminderItem]
    
    init(for calendar: EKCalendar, with reminderItems: [ReminderItem]) {
        self.id = calendar.calendarIdentifier
        self.calendar = calendar
        self.reminders = reminderItems.sortedReminders
    }
}
