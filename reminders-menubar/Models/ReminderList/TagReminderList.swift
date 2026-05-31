import Foundation

struct TagReminderList: Identifiable, Equatable {
    var id: String { tag.id }
    let tag: Tag
    let reminders: [ReminderItem]

    init(for tag: Tag, with reminderItems: [ReminderItem]) {
        self.tag = tag
        self.reminders = reminderItems.sortedReminders
    }
}
