import EventKit

extension Array where Element == ReminderItem {
    var sortedReminders: [ReminderItem] {
        return sorted(
            self,
            dueDateOnTop: UserPreferences.shared.showRemindersWithDueDateOnTop,
            byPriority: UserPreferences.shared.sortRemindersByPriority,
            using: UserPreferences.shared.reminderSortingOrder
        )
    }

    var sortedUpcomingReminders: [ReminderItem] {
        return sortedByDueDate(self)
    }

    private func sorted(
        _ reminders: [ReminderItem],
        dueDateOnTop: Bool,
        byPriority: Bool,
        using sortingOrder: RmbSortingOrder
    ) -> [ReminderItem] {
        if dueDateOnTop {
            var (dueDateReminders, undatedReminders) = reminders.separated(by: { $0.reminder.hasDueDate })

            dueDateReminders = sortedByDueDate(dueDateReminders)
            undatedReminders = sortedByPriority(undatedReminders, enabled: byPriority, using: sortingOrder)

            return dueDateReminders + undatedReminders
        }

        return sortedByPriority(reminders, enabled: byPriority, using: sortingOrder)
    }

    private func sortedByPriority(
        _ reminders: [ReminderItem],
        enabled: Bool,
        using sortingOrder: RmbSortingOrder
    ) -> [ReminderItem] {
        if enabled {
            let remindersByPriority = PrioritizedReminders(reminders)
            return sortedByOrder(remindersByPriority.high, using: sortingOrder) +
                sortedByOrder(remindersByPriority.medium, using: sortingOrder) +
                sortedByOrder(remindersByPriority.low, using: sortingOrder) +
                sortedByOrder(remindersByPriority.none, using: sortingOrder)
        }

        return sortedByOrder(reminders, using: sortingOrder)
    }

    private func sortedByDueDate(_ reminders: [ReminderItem]) -> [ReminderItem] {
        reminders.sorted(by: {
            let firstDate = $0.reminder.dueDateComponents?.date ?? Date.distantPast
            let secondDate = $1.reminder.dueDateComponents?.date ?? Date.distantPast
            return firstDate.compare(secondDate) == .orderedAscending
        })
    }

    private func sortedByOrder(
        _ reminders: [ReminderItem],
        using sortingOrder: RmbSortingOrder
    ) -> [ReminderItem] {
        switch sortingOrder {
        case .defaultOrder:
            return sortedByDefaultOrder(reminders)
        case .newestFirst:
            return reminders.sorted(by: {
                let firstDate = $0.reminder.completionDate ?? $0.reminder.creationDate ?? Date.distantPast
                let secondDate = $1.reminder.completionDate ?? $1.reminder.creationDate ?? Date.distantPast
                return firstDate.compare(secondDate) == .orderedDescending
            })
        case .oldestFirst:
            return reminders.sorted(by: {
                let firstDate = $0.reminder.completionDate ?? $0.reminder.creationDate ?? Date.distantPast
                let secondDate = $1.reminder.completionDate ?? $1.reminder.creationDate ?? Date.distantPast
                return firstDate.compare(secondDate) == .orderedAscending
            })
        }
    }

    private func sortedByDefaultOrder(_ reminders: [ReminderItem]) -> [ReminderItem] {
        var orderLookup: [String: Int] = [:]
        let calendarGroups = Dictionary(grouping: reminders, by: { $0.reminder.calendar.calendarIdentifier })
        for (_, groupReminders) in calendarGroups {
            if let calendar = groupReminders.first?.reminder.calendar,
               let ordering = calendar.reminderOrdering {
                for (index, reminderId) in ordering.enumerated() {
                    orderLookup[reminderId] = index
                }
            }
        }

        guard !orderLookup.isEmpty else {
            return reminders
        }

        return reminders.sorted(by: {
            let firstOrder = orderLookup[$0.id] ?? Int.max
            let secondOrder = orderLookup[$1.id] ?? Int.max
            return firstOrder < secondOrder
        })
    }
}
