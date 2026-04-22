import EventKit

enum RmbRecurrenceOption: Equatable {
    case none // swiftlint:disable:this discouraged_none_name
    case daily
    case weekly
    case monthly
    case yearly
    case custom

    init(from rules: [EKRecurrenceRule]?) {
        guard let rules, !rules.isEmpty else {
            self = .none
            return
        }

        guard rules.count == 1, let rule = rules.first, rule.interval == 1, rule.hasNoAdditionalConstraints else {
            self = .custom
            return
        }

        switch rule.frequency {
        case .daily:
            self = .daily
        case .weekly:
            self = .weekly
        case .monthly:
            self = .monthly
        case .yearly:
            self = .yearly
        @unknown default:
            self = .custom
        }
    }

    var ekRecurrenceRule: EKRecurrenceRule? {
        switch self {
        case .daily:
            return EKRecurrenceRule(recurrenceWith: .daily, interval: 1, end: nil)
        case .weekly:
            return EKRecurrenceRule(recurrenceWith: .weekly, interval: 1, end: nil)
        case .monthly:
            return EKRecurrenceRule(recurrenceWith: .monthly, interval: 1, end: nil)
        case .yearly:
            return EKRecurrenceRule(recurrenceWith: .yearly, interval: 1, end: nil)
        case .none, .custom:
            return nil
        }
    }

    var title: String {
        switch self {
        case .none:
            return rmbLocalized(.reminderRecurrenceNoneLabel)
        case .custom:
            return rmbLocalized(.reminderRecurrenceCustomLabel)
        case .daily, .weekly, .monthly, .yearly:
            return ekRecurrenceRule?.title ?? ""
        }
    }
}
