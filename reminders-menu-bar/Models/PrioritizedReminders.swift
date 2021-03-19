import EventKit

struct PrioritizedReminders {
    let high: [EKReminder]
    let medium: [EKReminder]
    let low: [EKReminder]
    let none: [EKReminder]
    
    init(_ reminders: [EKReminder]) {
        let remindersByPriority = Dictionary(grouping: reminders, by: { $0.ekPriority })
        high = remindersByPriority[.high] ?? []
        medium = remindersByPriority[.medium] ?? []
        low = remindersByPriority[.low] ?? []
        none = remindersByPriority[.none] ?? []
    }
}
