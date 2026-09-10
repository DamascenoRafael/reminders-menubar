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

    func removingReminders(withIDs reminderIDs: Set<String>) -> ReminderItem? {
        guard !reminderIDs.contains(id) else { return nil }

        let remainingChildren = childReminders.compactMap {
            $0.removingReminders(withIDs: reminderIDs)
        }
        return ReminderItem(for: reminder, isChild: isChild, withChildren: remainingChildren)
    }
}
