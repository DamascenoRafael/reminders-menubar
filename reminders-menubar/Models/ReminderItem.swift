import EventKit

struct ReminderItem: Identifiable, Equatable {
    let id: String
    let reminder: EKReminder
    let childReminders: LabeledReminders
    let isChild: Bool
    let hasChildren: Bool
    
    init(for reminder: EKReminder, isChild: Bool = false, withChildren childReminders: [ReminderItem] = []) {
        self.id = reminder.calendarItemIdentifier
        self.reminder = reminder
        self.childReminders = LabeledReminders(for: childReminders)
        self.isChild = isChild
        self.hasChildren = !childReminders.isEmpty
    }
    
    static func == (lhs: ReminderItem, rhs: ReminderItem) -> Bool {
        return (
            lhs.id == rhs.id
            && lhs.reminder.lastModifiedDate == rhs.reminder.lastModifiedDate
            && lhs.childReminders == rhs.childReminders
        )
    }
}
