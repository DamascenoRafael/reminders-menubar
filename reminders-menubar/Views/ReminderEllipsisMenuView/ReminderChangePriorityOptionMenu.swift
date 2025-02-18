import SwiftUI
import EventKit

struct ReminderChangePriorityOptionMenu: View {
    var reminder: EKReminder

    @ViewBuilder
    func changePriorityButton(_ priority: EKReminderPriority, text: String) -> some View {
        let isSelected = priority == reminder.ekPriority
        Button(action: {
            reminder.ekPriority = priority
            RemindersService.shared.save(reminder: reminder)
        }) {
            SelectableView(title: text, isSelected: isSelected)
        }
    }

    var body: some View {
        Menu {
            changePriorityButton(.low, text: rmbLocalized(.editReminderPriorityLowOption))
            changePriorityButton(.medium, text: rmbLocalized(.editReminderPriorityMediumOption))
            changePriorityButton(.high, text: rmbLocalized(.editReminderPriorityHighOption))
            Divider()
            changePriorityButton(.none, text: rmbLocalized(.editReminderPriorityNoneOption))
        } label: {
            HStack {
                Image(systemName: "exclamationmark.circle")
                Text(rmbLocalized(.changeReminderPriorityMenuOption))
            }
        }
    }
}

#Preview {
    var reminder: EKReminder {
        let calendar = EKCalendar(for: .reminder, eventStore: .init())
        calendar.color = .systemTeal

        let reminder = EKReminder(eventStore: .init())
        reminder.title = "Look for awesome projects on GitHub"
        reminder.isCompleted = false
        reminder.calendar = calendar
        reminder.dueDateComponents = Date().dateComponents(withTime: true)
        reminder.ekPriority = .high

        return reminder
    }

    ReminderChangePriorityOptionMenu(reminder: reminder)
}
