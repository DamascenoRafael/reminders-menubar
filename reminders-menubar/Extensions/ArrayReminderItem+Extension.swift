import EventKit

extension Array where Element == ReminderItem {
    func sortedReminders(by sortOption: ReminderSortOption) -> [ReminderItem] {
        switch sortOption {
        case .default:
            return sortedRemindersByDefault(self)
        case .creationDateNewestFirst:
            return sortedByCreationDate(self, ascending: false)
        case .creationDateOldestFirst:
            return sortedByCreationDate(self, ascending: true)
        }
    }

    func sortedRemindersByPriority(by sortOption: ReminderSortOption) -> [ReminderItem] {
        let remindersByPriority = PrioritizedReminders(self)

        return sortedReminders(remindersByPriority.high, by: sortOption) +
            sortedReminders(remindersByPriority.medium, by: sortOption) +
            sortedReminders(remindersByPriority.low, by: sortOption) +
            sortedReminders(remindersByPriority.none, by: sortOption)
    }

    private func sortedReminders(_ reminders: [ReminderItem], by sortOption: ReminderSortOption) -> [ReminderItem] {
        reminders.sortedReminders(by: sortOption)
    }

    private func sortedRemindersByDefault(_ reminders: [ReminderItem]) -> [ReminderItem] {
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

    private func sortedByCreationDate(_ reminders: [ReminderItem], ascending: Bool) -> [ReminderItem] {
        reminders.sorted {
            let firstDate = $0.reminder.creationDate ?? $0.reminder.completionDate ?? $0.reminder.dueDateComponents?.date ?? Date.distantPast
            let secondDate = $1.reminder.creationDate ?? $1.reminder.completionDate ?? $1.reminder.dueDateComponents?.date ?? Date.distantPast

            if firstDate != secondDate {
                return ascending ? firstDate < secondDate : firstDate > secondDate
            }

            let firstTitle = $0.reminder.title.localizedLowercase
            let secondTitle = $1.reminder.title.localizedLowercase
            if firstTitle != secondTitle {
                return firstTitle < secondTitle
            }

            return $0.id < $1.id
        }
    }
}
