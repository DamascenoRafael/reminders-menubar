import SwiftUI
import EventKit

struct ReminderChangePriorityOptionMenu: View {
    var reminder: EKReminder

    func changePriorityToggle(_ priority: EKReminderPriority) -> some View {
        Toggle(isOn: Binding(
            get: { priority == reminder.ekPriority },
            set: { _ in
                reminder.ekPriority = priority
                RemindersService.shared.save(reminder: reminder)
            }
        )) {
            Text(priority.title)
        }
    }

    var body: some View {
        Menu {
            changePriorityToggle(.low)
            changePriorityToggle(.medium)
            changePriorityToggle(.high)
            Divider()
            changePriorityToggle(.none)
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
