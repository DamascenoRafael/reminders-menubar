import SwiftUI
import EventKit

struct ReminderChangeDueDateOptionMenu: View {
    var reminder: EKReminder

    enum ScheduleOption: CaseIterable {
        case today
        case tomorrow
        case thisWeekend
        case nextWeek

        var title: String {
            switch self {
            case .today:
                return rmbLocalized(.editReminderDueDateTodayOption)
            case .tomorrow:
                return rmbLocalized(.editReminderDueDateTomorrowOption)
            case .thisWeekend:
                return rmbLocalized(.editReminderDueDateThisWeekendOption)
            case .nextWeek:
                return rmbLocalized(.editReminderDueDateNextWeekOption)
            }
        }

        func newDate(for initialDate: Date) -> Date {
            let today = Date()
            let daysToAddForToday = Calendar.current.daysBetween(initialDate, and: today)

            var addingDays: Int {
                switch self {
                case .today:
                    return daysToAddForToday
                case .tomorrow:
                    return daysToAddForToday + 1
                case .thisWeekend:
                    let nextWeekend = Calendar.current.nextWeekend(startingAfter: today)?.start ?? today
                    return Calendar.current.daysBetween(initialDate, and: nextWeekend)
                case .nextWeek:
                    let isWeekend = Calendar.current.isDateInWeekend(today)
                    if isWeekend {
                        let todayWeekday = Calendar.current.component(.weekday, from: today)
                        // Monday is represented by Weekday = 2
                        let daysFromTodayToNextMonday = (9 - todayWeekday) % 7
                        return daysToAddForToday + daysFromTodayToNextMonday
                    }
                    return daysToAddForToday + 7
                }
            }

            return Calendar.current.date(byAdding: .day, value: addingDays, to: initialDate) ?? initialDate
        }

        func isSelected(for date: Date?) -> Bool {
            guard let date else {
                return false
            }

            return date.isSameDay(as: newDate(for: date))
        }
    }

    var body: some View {
        let reminderDate = reminder.dueDateComponents?.date
        let scheduleOptionSelected = ScheduleOption.allCases.first(where: { $0.isSelected(for: reminderDate) })
        let isAnyOptionSelected = !reminder.hasDueDate || (scheduleOptionSelected != nil)
        Menu {
            ForEach(ScheduleOption.allCases, id: \.self) { option in
                Button(action: {
                    let date = option.newDate(for: reminderDate ?? Date())
                    let hasTime = reminder.hasTime
                    reminder.removeDueDateAndAlarms()
                    reminder.addDueDateAndAlarm(for: date, withTime: hasTime)
                    RemindersService.shared.save(reminder: reminder)
                    let f = DateFormatter(); f.dateFormat = hasTime ? "yyyy-MM-dd HH:mm" : "yyyy-MM-dd"
                    LogService.shared.log(.info, .crud, "Changed due date (\(option.title)) to \(f.string(from: date)) for: \(reminder.title as String? ?? "(no title)")")
                }) {
                    SelectableView(
                        title: option.title,
                        isSelected: option == scheduleOptionSelected,
                        withPadding: isAnyOptionSelected
                    )
                }
            }

            Divider()

            Button(action: {
                reminder.removeDueDateAndAlarms()
                reminder.removeAllRecurrenceRules()
                RemindersService.shared.save(reminder: reminder)
                LogService.shared.log(.info, .crud, "Cleared due date for: \(reminder.title as String? ?? "(no title)")")
            }) {
                SelectableView(
                    title: rmbLocalized(.editReminderDueDateNoneOption),
                    isSelected: !reminder.hasDueDate,
                    withPadding: isAnyOptionSelected
                )
            }
        } label: {
            HStack {
                Image(systemName: "calendar")
                Text(rmbLocalized(.changeReminderDueDateMenuOption))
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

    ReminderChangeDueDateOptionMenu(reminder: reminder)
}
