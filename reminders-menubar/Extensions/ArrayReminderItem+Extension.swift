import EventKit

extension Array where Element == ReminderItem {
    var sortedReminders: [ReminderItem] {
        return sortedReminders(self)
    }
    
    var sortedRemindersByPriority: [ReminderItem] {
        let remindersByPriority = PrioritizedReminders(self)
        
        return sortedReminders(remindersByPriority.high) +
            sortedReminders(remindersByPriority.medium) +
            sortedReminders(remindersByPriority.low) +
            sortedReminders(remindersByPriority.none)
    }
    
    private func sortedReminders(_ reminders: [ReminderItem]) -> [ReminderItem] {
        var (dueDateReminders, undatedReminders) = reminders.separated(by: { $0.reminder.hasDueDate })
        
        dueDateReminders.sort(by: {
            let firstDate = $0.reminder.completionDate ?? $0.reminder.dueDateComponents?.date ?? Date.distantPast
            let secondDate = $1.reminder.completionDate ?? $1.reminder.dueDateComponents?.date ?? Date.distantPast
            let comparisonResult: ComparisonResult = $0.reminder.isCompleted ? .orderedDescending : .orderedAscending
            return firstDate.compare(secondDate) == comparisonResult
        })
        
        undatedReminders.sort(by: {
            let firstDate = $0.reminder.completionDate ?? $0.reminder.creationDate ?? Date.distantPast
            let secondDate = $1.reminder.completionDate ?? $1.reminder.creationDate ?? Date.distantPast
            return firstDate.compare(secondDate) == .orderedDescending
        })
        
        return dueDateReminders + undatedReminders
    }
}
