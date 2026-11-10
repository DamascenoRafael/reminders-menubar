import SwiftUI
import EventKit

struct ReminderEllipsisMenuView: View {
    @Binding var showingEditPopover: Bool
    @Binding var showingAddSubtaskSheet: Bool
    @Binding var showingRemoveAlert: Bool
    var onCopyReminder: () -> Void

    var reminder: EKReminder
    var reminderHasChildren: Bool

    var body: some View {
        Menu {
            showEditPopoverOptionButton()

            // NOTE: Apple Reminders only supports one level of subtasks.
            if reminder.parentId == nil {
                showAddSubtaskSheetOptionButton()
            }

            copyReminderButton()

            ReminderChangePriorityOptionMenu(reminder: reminder)

            ReminderChangeListOptionMenu(reminder: reminder, reminderHasChildren: reminderHasChildren)

            ReminderChangeDueDateOptionMenu(reminder: reminder)

            Divider()

            showRemoveAlertOptionButton()
        } label: {
            Image(rmbSymbol: .ellipsis)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .frame(width: 16, height: 16)
        .padding(.top, 1)
        .padding(.trailing, 6)
        .help(rmbLocalized(.remindersOptionsButtonHelp))
    }

    func copyReminderButton() -> some View {
        Button(action: {
            onCopyReminder()
        }) {
            HStack {
                Image(rmbSymbol: .docOnDoc)
                Text(rmbLocalized(.copyReminderButton))
            }
        }
    }

    func showEditPopoverOptionButton() -> some View {
        Button(action: {
            showingEditPopover = true
        }) {
            HStack {
                Image(rmbSymbol: .pencil)
                Text(rmbLocalized(.editReminderButton))
            }
        }
    }

    func showAddSubtaskSheetOptionButton() -> some View {
        Button(action: {
            showingAddSubtaskSheet = true
        }) {
            HStack {
                Image(rmbSymbol: .plus)
                Text(rmbLocalized(.addSubtaskButton))
            }
        }
    }

    func showRemoveAlertOptionButton() -> some View {
        Button(action: {
            showingRemoveAlert = true
        }) {
            HStack {
                Image(rmbSymbol: .trash)
                Text(rmbLocalized(.removeReminderButton))
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
        showingAddSubtaskSheet: .constant(false),
        showingRemoveAlert: .constant(false),
        onCopyReminder: {},
        reminder: reminder,
        reminderHasChildren: false
    )
}
