import SwiftUI
import EventKit

struct ReminderCompleteButton: View {
    var reminderItem: ReminderItem
    @State private var isAnimating = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isAnimating = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                reminderItem.reminder.isCompleted.toggle()
                RemindersService.shared.save(reminder: reminderItem.reminder)
                if reminderItem.reminder.isCompleted {
                    reminderItem.childReminders.uncompleted.forEach { uncompletedChild in
                        uncompletedChild.reminder.isCompleted = true
                        RemindersService.shared.save(reminder: uncompletedChild.reminder)
                    }
                }
                isAnimating = false
            }
        }) {
            Image(systemName: isAnimating ? "checkmark.circle.fill" : (reminderItem.reminder.isCompleted ? "largecircle.fill.circle" : "circle"))
                .resizable()
                .frame(width: 16, height: 16)
                .padding(.top, 1)
                .foregroundColor(Color(reminderItem.reminder.calendar.color))
                .scaleEffect(isAnimating ? 1.2 : 1.0)
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
