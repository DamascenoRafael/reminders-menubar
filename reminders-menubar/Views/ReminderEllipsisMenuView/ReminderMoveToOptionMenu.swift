import SwiftUI
import EventKit

struct ReminderMoveToOptionMenu: View {
    @EnvironmentObject var remindersData: RemindersData
    
    var reminder: EKReminder
    var reminderHasChildren: Bool

    var body: some View {
        let otherCalendars = remindersData.calendars.filter {
            $0.calendarIdentifier != reminder.calendar.calendarIdentifier
        }
        if !otherCalendars.isEmpty, !reminderHasChildren {
            Menu {
                ForEach(otherCalendars, id: \.calendarIdentifier) { calendar in
                    // TODO: Fix the warning from Xcode when editing the reminder calendar:
                    // [utility] You are about to trigger decoding the resolution token map from JSON data.
                    // This is probably not what you want for performance to trigger it from -isEqual:,
                    // unless you are running Tests then it's fine
                    // {class: REMAccountStorage, self-map: (null), other-map: (null)}
                    Button(action: {
                        reminder.calendar = calendar
                        RemindersService.shared.save(reminder: reminder)
                    }) {
                        SelectableView(title: calendar.title, color: Color(calendar.color))
                    }
                }
            } label: {
                HStack {
                    Image(systemName: "folder")
                    Text(rmbLocalized(.reminderMoveToMenuOption))
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

    ReminderMoveToOptionMenu(reminder: reminder, reminderHasChildren: false)
        .environmentObject(RemindersData())
}
