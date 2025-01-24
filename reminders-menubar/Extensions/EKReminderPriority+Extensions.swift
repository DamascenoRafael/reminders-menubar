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
    
    var nextPriority: EKReminderPriority {
        switch self {
        case .low:
            return .medium
        case .medium:
            return .high
        case .high:
            return .none
        default:
            return .low
        }
    }
}
