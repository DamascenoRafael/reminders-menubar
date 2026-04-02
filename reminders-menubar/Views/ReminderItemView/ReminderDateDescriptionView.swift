import SwiftUI
import EventKit

struct ReminderDateDescriptionView: View {
    var dateDescription: String
    var isExpired: Bool
    var hasRecurrenceRules: Bool
    var recurrenceRules: [EKRecurrenceRule]?

    var body: some View {
        HStack {
            HStack {
                Image(systemName: "calendar")
                Text(dateDescription)
                    .foregroundColor(isExpired ? .red : .secondary)
            }
            .padding(.trailing, 5)

            if hasRecurrenceRules {
                Image(systemName: "repeat")
                Text(recurrenceLabel(recurrenceRules?.first))
            }

            Spacer()
        }
        .font(.footnote)
        .foregroundColor(.secondary)
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
        recurrenceRules: nil
    )
}
