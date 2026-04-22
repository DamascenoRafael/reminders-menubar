import EventKit

extension EKRecurrenceRule {
    var hasNoAdditionalConstraints: Bool {
        daysOfTheWeek == nil &&
        daysOfTheMonth == nil &&
        daysOfTheYear == nil &&
        weeksOfTheYear == nil &&
        monthsOfTheYear == nil &&
        setPositions == nil
    }

    var title: String {
        switch frequency {
        case .daily:
            return rmbLocalized(.reminderRecurrenceDailyLabel, arguments: interval)
        case .weekly:
            return rmbLocalized(.reminderRecurrenceWeeklyLabel, arguments: interval)
        case .monthly:
            return rmbLocalized(.reminderRecurrenceMonthlyLabel, arguments: interval)
        case .yearly:
            return rmbLocalized(.reminderRecurrenceYearlyLabel, arguments: interval)
        @unknown default:
            return ""
        }
    }
}
