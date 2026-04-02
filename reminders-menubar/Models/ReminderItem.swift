import EventKit

struct ReminderItem: Identifiable, Equatable {
    let id: String
    let reminder: EKReminder
    let lastModifiedDate: Date?
    let childReminders: [ReminderItem]
    let isChild: Bool
    let hasChildren: Bool
    
    init(for reminder: EKReminder, isChild: Bool = false, withChildren childReminders: [ReminderItem] = []) {
        self.id = reminder.calendarItemIdentifier
        self.reminder = reminder
        self.lastModifiedDate = reminder.lastModifiedDate
        self.childReminders = childReminders.sortedReminders
        self.isChild = isChild
        self.hasChildren = !childReminders.isEmpty
    }
    
    static func == (lhs: ReminderItem, rhs: ReminderItem) -> Bool {
        return (
            lhs.id == rhs.id
            && lhs.lastModifiedDate == rhs.lastModifiedDate
            && lhs.childReminders == rhs.childReminders
        )
    }
}
