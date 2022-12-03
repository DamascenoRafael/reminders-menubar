import EventKit

extension EKReminder {
    private var maxDueDate: Date? {
        guard let date = dueDateComponents?.date else {
            return nil
        }
        
        if hasTime {
            // if the reminder has a time then it expires after its own date.
            return date
        }

        // if the reminder doesn’t have a time then it expires the next day.
        return Calendar.current.date(byAdding: .day, value: 1, to: date)
    }
    
    var hasDueDate: Bool {
        return dueDateComponents != nil
    }
    
    var hasTime: Bool {
        return dueDateComponents?.hour != nil
    }
    
    var ekPriority: EKReminderPriority {
        get {
            return EKReminderPriority(rawValue: UInt(self.priority)) ?? .none
        }
        set {
            self.priority = Int(newValue.rawValue)
        }
    }
    
    var prioritySystemImage: String? {
        switch self.ekPriority {
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
    
    var isExpired: Bool {
        maxDueDate?.isPast ?? false
    }
    
    var relativeDateDescription: String? {
        guard let date = dueDateComponents?.date else {
            return nil
        }
        
        return date.relativeDateDescription(withTime: hasTime)
    }
    
    func update(with rmbReminder: RmbReminder) {
        if !rmbReminder.title.trimmingCharacters(in: .whitespaces).isEmpty {
            title = rmbReminder.title
        }
        notes = rmbReminder.notes
        
        if rmbReminder.hasDueDate {
            let rmbDateComponents = rmbReminder.date.dateComponents(withTime: rmbReminder.hasTime)
            dueDateComponents = rmbDateComponents
            
            let ekAlarm = EKAlarm(absoluteDate: rmbDateComponents.date!)
            alarms = [ekAlarm]
        } else {
            dueDateComponents = nil
            alarms = nil
        }

        ekPriority = rmbReminder.priority
    }
}
