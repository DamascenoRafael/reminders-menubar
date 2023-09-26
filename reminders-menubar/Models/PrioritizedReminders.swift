import EventKit

struct PrioritizedReminders {
    let high: [ReminderItem]
    let medium: [ReminderItem]
    let low: [ReminderItem]
    let none: [ReminderItem]
    
    init(_ reminderItems: [ReminderItem]) {
        let remindersByPriority = Dictionary(grouping: reminderItems, by: { $0.reminder.ekPriority })
        high = remindersByPriority[.high] ?? []
        medium = remindersByPriority[.medium] ?? []
        low = remindersByPriority[.low] ?? []
        none = remindersByPriority[.none] ?? []
    }
}
