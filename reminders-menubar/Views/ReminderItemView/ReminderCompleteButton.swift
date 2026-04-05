import SwiftUI
import EventKit

struct ReminderCompleteButton: View {
    var reminderItem: ReminderItem
    @Binding var isPendingCompletion: Bool

    @State private var isFilled = false
    @State private var completionTask: Task<Void, Never>?

    private let completionDelayInSeconds: Double = 1.5

    private var isShowingFilled: Bool {
        reminderItem.reminder.isCompleted || isFilled
    }

    var body: some View {
        Button(action: {
            handleButtonTap()
        }) {
            Image(systemName: isShowingFilled ? "largecircle.fill.circle" : "circle")
                .resizable()
                .frame(width: 14, height: 14)
                .foregroundColor(Color(reminderItem.reminder.calendar.color))
                .transition(.scale(scale: 0.1).combined(with: .opacity))
                .id(isShowingFilled)
                .padding(.top, 2)
        }
        .buttonStyle(PlainButtonStyle())
        .onDisappear {
            if isPendingCompletion {
                completionTask?.cancel()
                completionTask = nil
                completeReminder()
            }
        }
    }

    private func handleButtonTap() {
        if isPendingCompletion {
            cancelPendingCompletion()
        } else if reminderItem.reminder.isCompleted {
            reminderItem.reminder.isCompleted = false
            RemindersService.shared.save(reminder: reminderItem.reminder)
        } else {
            startPendingCompletion()
        }
    }

    private func startPendingCompletion() {
        isPendingCompletion = true
        withAnimation(.easeOut(duration: 0.25)) {
            isFilled = true
        }

        completionTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(completionDelayInSeconds * 1_000_000_000))
            guard !Task.isCancelled else { return }
            completeReminder()
        }
    }

    private func cancelPendingCompletion() {
        completionTask?.cancel()
        completionTask = nil
        withAnimation(.easeOut(duration: 0.25)) {
            isFilled = false
        }
        isPendingCompletion = false
    }

    private func completeReminder() {
        reminderItem.reminder.isCompleted = true
        RemindersService.shared.save(reminder: reminderItem.reminder)
        reminderItem.childReminders.forEach { child in
            child.reminder.isCompleted = true
            RemindersService.shared.save(reminder: child.reminder)
        }
        isFilled = false
        isPendingCompletion = false
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

    VStack {
        ReminderCompleteButton(reminderItem: reminderItem, isPendingCompletion: .constant(false))

        ReminderCompleteButton(reminderItem: reminderItem, isPendingCompletion: .constant(true))
    }
    .frame(width: 100)
}
