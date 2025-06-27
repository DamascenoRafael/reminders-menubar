import SwiftUI
import EventKit

struct ReminderDateDescriptionView: View {
    var dateDescription: String
    var isExpired: Bool
    var hasRecurrenceRules: Bool
    var recurrenceRules: [EKRecurrenceRule]?
    var calendarTitle: String
    var showCalendarTitleOnDueDate: Bool

    var body: some View {
        HStack {
            HStack {
                Image(systemName: "calendar")
                Text(dateDescription)
                    .foregroundColor(isExpired ? .red : nil)
            }
            .padding(.trailing, 5)

            if hasRecurrenceRules {
                Image(systemName: "repeat")
                Text(recurrenceLabel(recurrenceRules?.first))
            }

            if showCalendarTitleOnDueDate {
                Spacer()

                Text(calendarTitle)
            }
        }
        .font(.footnote)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.trailing, 12)
    }

    func recurrenceLabel(_ rule: EKRecurrenceRule?) -> String {
        let interval = rule?.interval ?? 1

        switch rule?.frequency {
        case .daily:
            return rmbLocalized(.reminderRecurrenceDailyLabel, arguments: interval)
        case .weekly:
            return rmbLocalized(.reminderRecurrenceWeeklyLabel, arguments: interval)
        case .monthly:
            return rmbLocalized(.reminderRecurrenceMonthlyLabel, arguments: interval)
        case .yearly:
            return rmbLocalized(.reminderRecurrenceYearlyLabel, arguments: interval)
        default:
            return ""
        }
    }
}

#Preview {
    ReminderDateDescriptionView(
        dateDescription: Date().relativeDateDescription(withTime: true),
        isExpired: false,
        hasRecurrenceRules: false,
        recurrenceRules: nil,
        calendarTitle: "Reminders",
        showCalendarTitleOnDueDate: true
    )
}
