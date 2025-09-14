import SwiftUI
import EventKit

struct ReminderCompleteButton: View {
    var reminderItem: ReminderItem

    var body: some View {
        Button(action: {
            reminderItem.reminder.isCompleted.toggle()
            RemindersService.shared.save(reminder: reminderItem.reminder)
            Task {
                if FirebaseManager.isAvailable && FirebaseManager.shared.isSignedIn {
                    await BobFirestoreSyncService.shared.reportCompletion(for: reminderItem.reminder)
                } else {
                    await BobSyncService.shared.reportCompletion(for: reminderItem.reminder)
                }
            }
            if reminderItem.reminder.isCompleted {
                reminderItem.childReminders.uncompleted.forEach { uncompletedChild in
                    uncompletedChild.reminder.isCompleted = true
                    RemindersService.shared.save(reminder: uncompletedChild.reminder)
                    Task {
                        if FirebaseManager.isAvailable && FirebaseManager.shared.isSignedIn {
                            await BobFirestoreSyncService.shared.reportCompletion(for: uncompletedChild.reminder)
                        } else {
                            await BobSyncService.shared.reportCompletion(for: uncompletedChild.reminder)
                        }
                    }
                }
            }
        }) {
            Image(systemName: reminderItem.reminder.isCompleted ? "largecircle.fill.circle" : "circle")
                .resizable()
                .frame(width: 16, height: 16)
                .padding(.top, 1)
                .foregroundColor(Color(reminderItem.reminder.calendar.color))
        }
        .buttonStyle(PlainButtonStyle())
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

        return reminder
    }
    let reminderItem = ReminderItem(for: reminder)

    ReminderCompleteButton(reminderItem: reminderItem)
}
