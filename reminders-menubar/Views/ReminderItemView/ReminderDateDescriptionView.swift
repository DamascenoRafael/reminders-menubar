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
                Image(rmbSymbol: .calendar)
                Text(dateDescription)
                    .foregroundColor(isExpired ? .rmbColor(.expiredDate) : .secondary)
            }
            .padding(.trailing, 5)

            if hasRecurrenceRules {
                Image(rmbSymbol: .recurrence)
                Text(recurrenceLabel(recurrenceRules))
            }

            Spacer()
        }
        .font(.footnote)
        .foregroundColor(.secondary)
    }

    func recurrenceLabel(_ rules: [EKRecurrenceRule]?) -> String {
        guard rules?.count == 1, let rule = rules?.first, rule.hasNoAdditionalConstraints else {
            return ""
        }

        return rule.title
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
