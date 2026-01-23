import SwiftUI
import EventKit

struct ReminderDateDescriptionView: View {
    var dateDescription: String
    var isExpired: Bool
    var hasRecurrenceRules: Bool
    var recurrenceRules: [EKRecurrenceRule]?
    var calendarTitle: String
    var showCalendarTitleOnDueDate: Bool
    
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 4) {
            Text(dateDescription)
                .lineLimit(1)
                .foregroundColor(isExpired ? .red.opacity(0.7) : nil)

            if isHovered && showCalendarTitleOnDueDate {
                Text("@ \(calendarTitle)")
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
        .font(.system(size: 8))
        .frame(maxWidth: .infinity, alignment: .leading)
        .onHover { hovering in
            isHovered = hovering
        }
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
