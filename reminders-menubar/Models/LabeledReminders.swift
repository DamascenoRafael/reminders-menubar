struct LabeledReminders: Equatable {
    let completed: [ReminderItem]
    let uncompleted: [ReminderItem]
    
    init(for reminderItems: [ReminderItem]) {
        let (completedReminders, uncompletedReminders) = reminderItems.separated(by: { $0.reminder.isCompleted })
        self.completed = completedReminders.sortedRemindersByPriority
        self.uncompleted = uncompletedReminders.sortedRemindersByPriority
    }
}
