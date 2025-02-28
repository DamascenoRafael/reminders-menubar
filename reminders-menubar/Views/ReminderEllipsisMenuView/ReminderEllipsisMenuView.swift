import SwiftUI
import EventKit

struct ReminderEllipsisMenuView: View {
    @Binding var showingEditPopover: Bool
    @Binding var showingRemoveAlert: Bool

    var reminder: EKReminder
    var reminderHasChildren: Bool

    var body: some View {
        Menu {
            showEditPopoverOptionButton()

            ReminderChangePriorityOptionMenu(reminder: reminder)

            ReminderChangeListOptionMenu(reminder: reminder, reminderHasChildren: reminderHasChildren)

            Divider()

            showRemoveAlertOptionButton()
        } label: {
            Image(systemName: "ellipsis")
        }
        .menuStyle(BorderlessButtonMenuStyle(showsMenuIndicator: false))
        .frame(width: 16, height: 16)
        .padding(.top, 1)
        .padding(.trailing, 10)
        .help(rmbLocalized(.remindersOptionsButtonHelp))
    }

    func showEditPopoverOptionButton() -> some View {
        Button(action: {
            showingEditPopover = true
        }) {
            HStack {
                Image(systemName: "pencil")
                Text(rmbLocalized(.editReminderOptionButton))
            }
        }
    }

    func showRemoveAlertOptionButton() -> some View {
        Button(action: {
            showingRemoveAlert = true
        }) {
            HStack {
                Image(systemName: "minus.circle")
                Text(rmbLocalized(.removeReminderOptionButton))
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

    ReminderEllipsisMenuView(
        showingEditPopover: .constant(false),
        showingRemoveAlert: .constant(false),
        reminder: reminder,
        reminderHasChildren: false
    )
}
