import SwiftUI
import EventKit

struct ReminderCompleteButton: View {
    var reminderItem: ReminderItem
    @Binding var isPendingCompletion: Bool

    @EnvironmentObject private var remindersData: RemindersData
    @ObservedObject private var userPreferences = UserPreferences.shared
    @State private var isFilled = false
    @State private var completionTask: Task<Void, Never>?
    @State private var childrenCompletedByTask: [ReminderItem] = []

    private let completionDelayInSeconds: Double = 0.35

    private var isShowingFilled: Bool {
        reminderItem.reminder.isCompleted || isFilled
    }

    var body: some View {
        Button(action: {
            handleButtonTap()
        }) {
            Image(rmbSymbol: isShowingFilled ? .circleFilled : .circle)
                .resizable()
                .frame(width: 14, height: 14)
                .foregroundColor(Color(reminderItem.reminder.calendar.color))
                .transition(.scale(scale: 0.1).combined(with: .opacity))
                .id(isShowingFilled)
                .padding(.top, 2)
        }
        .buttonStyle(.plain)
        .onDisappear {
            if isPendingCompletion && !reminderItem.reminder.isCompleted {
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
        } else if userPreferences.completionAnimationEnabled {
            startPendingCompletion()
        } else {
            completeReminder()
            remindersData.optimisticallyRemove(reminderItem: reminderItem)
        }
    }

    private func startPendingCompletion() {
        isPendingCompletion = true
        withAnimation(.easeOut(duration: 0.15)) {
            isFilled = true
        }

        completionTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(completionDelayInSeconds * 1_000_000_000))
            guard !Task.isCancelled else { return }
            completeReminder()
        }
    }

    private func cancelPendingCompletion() {
        completionTask?.cancel()
        completionTask = nil

        if reminderItem.reminder.isCompleted {
            reminderItem.reminder.isCompleted = false
            RemindersService.shared.save(reminder: reminderItem.reminder)
            childrenCompletedByTask.forEach { child in
                child.reminder.isCompleted = false
                RemindersService.shared.save(reminder: child.reminder)
            }
            childrenCompletedByTask = []
        }

        withAnimation(.easeOut(duration: 0.15)) {
            isFilled = false
        }
        isPendingCompletion = false
    }

    private func completeReminder() {
        childrenCompletedByTask = reminderItem.childReminders.filter { !$0.reminder.isCompleted }
        reminderItem.reminder.isCompleted = true
        RemindersService.shared.save(reminder: reminderItem.reminder)
        childrenCompletedByTask.forEach { child in
            child.reminder.isCompleted = true
            RemindersService.shared.save(reminder: child.reminder)
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

        return reminder
    }
    let reminderItem = ReminderItem(for: reminder)

    VStack {
        ReminderCompleteButton(reminderItem: reminderItem, isPendingCompletion: .constant(false))

        ReminderCompleteButton(reminderItem: reminderItem, isPendingCompletion: .constant(true))
    }
    .frame(width: 100)
    .environmentObject(RemindersData())
}
