import EventKit

extension EKReminderPriority {
    var rmbSymbol: RmbSymbol? {
        switch self {
        case .high:
            return .priorityHigh
        case .medium:
            return .priorityMedium
        case .low:
            return .priorityLow
        default:
            return nil
        }
    }

    var title: String {
        switch self {
        case .high:
            rmbLocalized(.editReminderPriorityHighOption)
        case .medium:
            rmbLocalized(.editReminderPriorityMediumOption)
        case .low:
            rmbLocalized(.editReminderPriorityLowOption)
        default:
            rmbLocalized(.editReminderPriorityNoneOption)
        }
    }
}
