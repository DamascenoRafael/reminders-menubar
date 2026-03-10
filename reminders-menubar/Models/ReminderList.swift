import EventKit

struct ReminderList: Identifiable, Equatable {
    let id: String
    let calendar: EKCalendar
    let reminders: LabeledReminders
    
    init(
        for calendar: EKCalendar,
        with reminderItems: [ReminderItem],
        sortOption: ReminderSortOption = UserPreferences.shared.reminderSortOption
    ) {
        self.id = calendar.calendarIdentifier
        self.calendar = calendar
        self.reminders = LabeledReminders(for: reminderItems, sortOption: sortOption)
    }
}
