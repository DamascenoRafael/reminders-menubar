enum ReminderItemTree {
    struct ExclusionResult {
        let reminders: [ReminderItem]
        let excludedCount: Int
    }

    static func excluding(
        reminderIds excludedReminderIds: Set<String>,
        from reminders: [ReminderItem]
    ) -> ExclusionResult {
        guard !excludedReminderIds.isEmpty else {
            return ExclusionResult(reminders: reminders, excludedCount: 0)
        }

        return excluding(
            reminderIds: excludedReminderIds,
            from: reminders,
            isChildLevel: false
        )
    }

    private static func excluding(
        reminderIds excludedReminderIds: Set<String>,
        from reminders: [ReminderItem],
        isChildLevel: Bool
    ) -> ExclusionResult {
        var remainingReminders: [ReminderItem] = []
        var excludedCount = 0

        for reminderItem in reminders {
            let isExcluded = excludedReminderIds.contains(reminderItem.id)
            let remainingChildrenResult = excluding(
                reminderIds: excludedReminderIds,
                from: reminderItem.childReminders,
                isChildLevel: isExcluded ? isChildLevel : true // Promote retained children to the excluded item's level

            )
            excludedCount += remainingChildrenResult.excludedCount

            if isExcluded {
                excludedCount += 1
                remainingReminders.append(contentsOf: remainingChildrenResult.reminders)
            } else {
                remainingReminders.append(ReminderItem(
                    for: reminderItem.reminder,
                    isChild: isChildLevel,
                    withChildren: remainingChildrenResult.reminders
                ))
            }
        }

        return ExclusionResult(
            reminders: remainingReminders,
            excludedCount: excludedCount
        )
    }
}
