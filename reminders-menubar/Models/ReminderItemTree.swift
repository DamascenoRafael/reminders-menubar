enum ReminderItemTree {
    static func excluding(
        reminderIds excludedReminderIds: Set<String>,
        from reminders: [ReminderItem]
    ) -> [ReminderItem] {
        guard !excludedReminderIds.isEmpty else { return reminders }
        return excluding(
            reminderIds: excludedReminderIds,
            from: reminders,
            itemsAreChildren: false
        )
    }

    private static func excluding(
        reminderIds excludedReminderIds: Set<String>,
        from reminders: [ReminderItem],
        itemsAreChildren: Bool
    ) -> [ReminderItem] {
        return reminders.flatMap { reminderItem in
            let remainingChildren = excluding(
                reminderIds: excludedReminderIds,
                from: reminderItem.childReminders,
                itemsAreChildren: true
            )

            if excludedReminderIds.contains(reminderItem.id) {
                return remainingChildren.map {
                    ReminderItem(
                        for: $0.reminder,
                        isChild: itemsAreChildren,
                        withChildren: $0.childReminders
                    )
                }
            }

            return [
                ReminderItem(
                    for: reminderItem.reminder,
                    isChild: itemsAreChildren,
                    withChildren: remainingChildren
                )
            ]
        }
    }
}
