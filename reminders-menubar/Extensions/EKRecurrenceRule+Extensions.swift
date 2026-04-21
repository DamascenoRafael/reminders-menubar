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
}
