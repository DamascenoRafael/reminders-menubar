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
    
    var isExpired: Bool {
        maxDueDate?.isPast ?? false
    }
    
    var relativeDateDescription: String? {
        guard let date = dueDateComponents?.date else {
            return nil
        }
        
        return date.relativeDateDescription(withTime: hasTime)
    }
    
    private var reminderBackingObject: AnyObject? {
        let backingObjectSelector = NSSelectorFromString("backingObject")
        let reminderSelector = NSSelectorFromString("_reminder")
        
        guard let unmanagedBackingObject = self.perform(backingObjectSelector),
              let unmanagedReminder = unmanagedBackingObject.takeUnretainedValue().perform(reminderSelector) else {
            return nil
        }
        
        return unmanagedReminder.takeUnretainedValue()
    }
    
    // NOTE: This is a workaround to access the URL saved in a reminder.
    // This property is not accessible through the conventional API.
    var attachedUrl: URL? {
        let attachmentsSelector = NSSelectorFromString("attachments")
        
        guard let unmanagedAttachments = reminderBackingObject?.perform(attachmentsSelector),
              let attachments = unmanagedAttachments.takeUnretainedValue() as? [AnyObject] else {
            return nil
        }
        
        for item in attachments {
            // NOTE: Attachments can be of type REMURLAttachment or REMImageAttachment.
            let attachmentType = type(of: item).description()
            guard attachmentType == "REMURLAttachment" else {
                continue
            }
            
            guard let unmanagedUrl = item.perform(NSSelectorFromString("url")),
                  let url = unmanagedUrl.takeUnretainedValue() as? URL else {
                continue
            }
            
            return url
        }
        
        return nil
    }
    
    // NOTE: This is a workaround to access the mail linked to a reminder.
    // This property is not accessible through the conventional API.
    var mailUrl: URL? {
        let userActivitySelector = NSSelectorFromString("userActivity")
        let storageSelector = NSSelectorFromString("storage")
        
        guard let unmanagedUserActivity = reminderBackingObject?.perform(userActivitySelector),
              let unmanagedUserActivityStorage = unmanagedUserActivity.takeUnretainedValue().perform(storageSelector),
              let userActivityStorageData = unmanagedUserActivityStorage.takeUnretainedValue() as? Data else {
            return nil
        }
        
        // NOTE: UserActivity type is UniversalLink, so in theory it could be targeting apps other than Mail.
        // If it starts with "message:" then it is related to Mail.
        guard let userActivityStorageString = String(bytes: userActivityStorageData, encoding: .utf8),
              userActivityStorageString.starts(with: "message:") else {
            return nil
        }
        
        return URL(string: userActivityStorageString)
    }
    
    // NOTE: This is a workaround to access the parent reminder id of a reminder.
    // This property is not accessible through the conventional API.
    var parentId: String? {
        let parentReminderSelector = NSSelectorFromString("parentReminderID")
        let uuidSelector = NSSelectorFromString("uuid")
        
        guard let unmanagedParentReminder = reminderBackingObject?.perform(parentReminderSelector),
              let unmanagedParentReminderId = unmanagedParentReminder.takeUnretainedValue().perform(uuidSelector),
              let parentReminderId = unmanagedParentReminderId.takeUnretainedValue() as? UUID else {
            return nil
        }
        
        return parentReminderId.uuidString
    }
    
    func update(with rmbReminder: RmbReminder) {
        let trimmedTitle = rmbReminder.title.trimmingCharacters(in: .whitespaces)
        if !trimmedTitle.isEmpty {
            title = trimmedTitle
        }
        
        notes = rmbReminder.notes
        
        // NOTE: Preventing unnecessary reminder dueDate/EKAlarm overwriting.
        if rmbReminder.hasDateChanges {
            removeDueDateAndAlarms()
            if rmbReminder.hasDueDate {
                addDueDateAndAlarm(for: rmbReminder.date, withTime: rmbReminder.hasTime)
            } else {
                // NOTE: A reminder that has no due date cannot be a repeating reminder
                removeAllRecurrenceRules()
            }
        }
        
        ekPriority = rmbReminder.priority
        calendar = rmbReminder.calendar
    }
    
    func removeDueDateAndAlarms() {
        dueDateComponents = nil
        alarms?.forEach { alarm in
            removeAlarm(alarm)
        }
    }

    func removeAllRecurrenceRules() {
        recurrenceRules?.forEach { rule in
            removeRecurrenceRule(rule)
        }
    }

    func addDueDateAndAlarm(for date: Date, withTime hasTime: Bool) {
        let dateComponents = date.dateComponents(withTime: hasTime)
        dueDateComponents = dateComponents

        // NOTE: In Apple Reminders only reminders with time have an alarm.
        if hasTime {
            let ekAlarm = EKAlarm(absoluteDate: dateComponents.date!)
            addAlarm(ekAlarm)
        }
    }

    @MainActor
    @discardableResult
    func rmbUpdateTag(newTag: String?, removing previousTag: String?) -> Bool {
        guard #available(macOS 12.0, *) else { return false }

        func normalize(_ value: String?) -> String? {
            guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else { return nil }
            return trimmed
        }

        let normalizedPrevious = normalize(previousTag)
        let normalizedNew = normalize(newTag)

        var currentTags = (value(forKey: "tags") as? [String]) ?? []
        let original = currentTags

        if let previous = normalizedPrevious {
            currentTags.removeAll { $0.compare(previous, options: .caseInsensitive) == .orderedSame }
        }

        if let desired = normalizedNew,
           !currentTags.contains(where: { $0.compare(desired, options: .caseInsensitive) == .orderedSame }) {
            currentTags.append(desired)
        }

        // Drop empty entries in case trimming removed everything
        currentTags.removeAll { normalize($0) == nil }

        if original != currentTags {
            setValue(currentTags, forKey: "tags")
            return true
        }
        return false
    }
}
