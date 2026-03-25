import EventKit

extension EKReminderPriority {
    var systemImage: String? {
        switch self {
        case .high:
            return "exclamationmark.3"
        case .medium:
            return "exclamationmark.2"
        case .low:
            return "exclamationmark"
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
