import EventKit

extension Array where Element == EKReminder {
    var sortedReminders: [EKReminder] {
        return sortedReminders(self)
    }
    
    var sortedRemindersByPriority: [EKReminder] {
        let remindersByPriority = PrioritizedReminders(self)
        
        return sortedReminders(remindersByPriority.high) +
            sortedReminders(remindersByPriority.medium) +
            sortedReminders(remindersByPriority.low) +
            sortedReminders(remindersByPriority.none)
    }
    
    private func sortedReminders(_ reminders: [EKReminder]) -> [EKReminder] {
        var (dueDateReminders, undatedReminders) = reminders.separeted(by: { $0.hasDueDate })
        
        dueDateReminders.sort(by: {
                let firstDate = $0.completionDate ?? $0.dueDateComponents?.date ?? Date.distantPast
                let secondDate = $1.completionDate ?? $1.dueDateComponents?.date ?? Date.distantPast
                let comparisonResult: ComparisonResult = $0.isCompleted ? .orderedDescending : .orderedAscending
                return firstDate.compare(secondDate) == comparisonResult
        })
        
        undatedReminders.sort(by: {
                let firstDate = $0.completionDate ?? $0.creationDate ?? Date.distantPast
                let secondDate = $1.completionDate ?? $1.creationDate ?? Date.distantPast
                return firstDate.compare(secondDate) == .orderedDescending
        })
        
        return dueDateReminders + undatedReminders
    }
}
