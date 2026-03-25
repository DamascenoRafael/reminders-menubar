import SwiftUI
import EventKit

struct ReminderChangePriorityOptionMenu: View {
    var reminder: EKReminder

    @ViewBuilder
    func changePriorityButton(_ priority: EKReminderPriority) -> some View {
        let isSelected = priority == reminder.ekPriority
        Button(action: {
            reminder.ekPriority = priority
            RemindersService.shared.save(reminder: reminder)
        }) {
            SelectableView(title: priority.title, isSelected: isSelected)
        }
    }

    var body: some View {
        Menu {
            changePriorityButton(.low)
            changePriorityButton(.medium)
            changePriorityButton(.high)
            Divider()
            changePriorityButton(.none)
        } label: {
            HStack {
                Image(systemName: "exclamationmark.3")
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
