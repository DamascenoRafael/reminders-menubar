import SwiftUI
import EventKit

struct ReminderChangeListOptionMenu: View {
    @EnvironmentObject var remindersData: RemindersData
    
    var reminder: EKReminder
    var reminderHasChildren: Bool

    var body: some View {
        if !reminderHasChildren {
            let currentCalendarId = reminder.calendar.calendarIdentifier
            Menu {
                ForEach(remindersData.availableCalendars, id: \.calendarIdentifier) { calendar in
                    Toggle(isOn: Binding(
                        get: { calendar.calendarIdentifier == currentCalendarId },
                        set: { _ in
                            guard calendar.calendarIdentifier != currentCalendarId else { return }
                            reminder.calendar = calendar
                            RemindersService.shared.save(reminder: reminder)
                        }
                    )) {
                        ColoredDotTitle.text(calendar.title, color: Color(calendar.color))
                    }
                }
            } label: {
                HStack {
                    Image(systemName: "folder")
                    Text(rmbLocalized(.changeReminderListMenuOption))
                }
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

    ReminderChangeListOptionMenu(reminder: reminder, reminderHasChildren: false)
        .environmentObject(RemindersData())
}
