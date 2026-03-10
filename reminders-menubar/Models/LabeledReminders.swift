struct LabeledReminders: Equatable {
    let completed: [ReminderItem]
    let uncompleted: [ReminderItem]
    
    init(for reminderItems: [ReminderItem], sortOption: ReminderSortOption = UserPreferences.shared.reminderSortOption) {
        let (completedReminders, uncompletedReminders) = reminderItems.separated(by: { $0.reminder.isCompleted })
        self.completed = completedReminders.sortedRemindersByPriority(by: sortOption)
        self.uncompleted = uncompletedReminders.sortedRemindersByPriority(by: sortOption)
    }
}
