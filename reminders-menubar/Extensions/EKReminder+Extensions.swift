import EventKit

extension EKReminder {
    // MARK: - Computed properties

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
    
    // MARK: - Private API access

    // NOTE: This is a workaround to access the URL saved in a reminder.
    // This property is not accessible through the conventional API.
    var attachedUrl: URL? {
        guard let backingObject = reminderBackingObject,
              let attachments = performPrivateSelector("attachments", on: backingObject) as? [AnyObject] else {
            return nil
        }
        
        for item in attachments {
            // NOTE: Attachments can be of type REMURLAttachment or REMImageAttachment.
            let attachmentType = type(of: item).description()
            guard attachmentType == "REMURLAttachment" else {
                continue
            }

            if let url = performPrivateSelector("url", on: item) as? URL {
                return url
            }
        }
        
        return nil
    }
    
    // NOTE: This is a workaround to access the mail linked to a reminder.
    // This property is not accessible through the conventional API.
    var mailUrl: URL? {
        guard let backingObject = reminderBackingObject,
              let userActivity = performPrivateSelector("userActivity", on: backingObject),
              let userActivityStorageData = performPrivateSelector("storage", on: userActivity) as? Data else {
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
        guard let backingObject = reminderBackingObject,
              let parentReminder = performPrivateSelector("parentReminderID", on: backingObject),
              let parentReminderId = performPrivateSelector("uuid", on: parentReminder) as? UUID else {
            return nil
        }
        
        return parentReminderId.uuidString
    }

    // NOTE: This is a workaround to access the tags (hashtags) saved in a reminder.
    // This property is not accessible through the conventional API.
    @available(macOS 12, *)
    var ekTags: [Tag] {
        guard let backingObject = reminderBackingObject,
              let hashtags = performPrivateSelector("hashtags", on: backingObject) as? NSSet else {
            return []
        }

        return hashtags.allObjects.compactMap {
            performPrivateSelector("name", on: $0 as AnyObject) as? String
        }
        .map { Tag($0) }
        .sorted()
    }

    private var reminderBackingObject: AnyObject? {
        guard let backingObject = performPrivateSelector("backingObject", on: self) else {
            return nil
        }
        return performPrivateSelector("_reminder", on: backingObject)
    }

    private func performPrivateSelector(_ name: String, on object: AnyObject, with arg: AnyObject? = nil) -> AnyObject? {
        let selector = NSSelectorFromString(name)
        guard object.responds(to: selector) else { return nil }
        if let arg {
            return object.perform(selector, with: arg)?.takeUnretainedValue()
        }
        return object.perform(selector)?.takeUnretainedValue()
    }

    // MARK: - Update reminder methods

    func update(with rmbReminder: RmbReminder) {
        let trimmedTitle = rmbReminder.title.trimmingCharacters(in: .whitespaces)
        if !trimmedTitle.isEmpty {
            title = trimmedTitle
        }
        
        notes = rmbReminder.notes
        
        // NOTE: Preventing unnecessary dueDate/EKAlarm overwriting.
        if rmbReminder.hasDateChanges {
            removeDueDateAndAlarms()
            if rmbReminder.hasDueDate {
                addDueDateAndAlarm(for: rmbReminder.date, withTime: rmbReminder.hasTime)
            }
        }
        
        // NOTE: Preventing unnecessary recurrence overwriting.
        if rmbReminder.hasRecurrenceChanges {
            switch rmbReminder.recurrence {
            case .custom:
                // NOTE: Custom recurrence should not be modified; preserve original rules
                break
            case .none:
                removeAllRecurrenceRules()
            case .daily, .weekly, .monthly, .yearly:
                removeAllRecurrenceRules()
                if let rule = rmbReminder.recurrence.ekRecurrenceRule {
                    addRecurrenceRule(rule)
                }
            }
        }
        
        ekPriority = rmbReminder.priority
        calendar = rmbReminder.calendar
    }

    @available(macOS 12, *)
    func updateTags(_ newTags: [Tag]) {
        guard Set(ekTags) != Set(newTags) else {
            return
        }

        // NOTE: Setup save request via REMSaveRequest.
        guard let backingObject = reminderBackingObject,
              let store = performPrivateSelector("store", on: backingObject),
              let saveRequestClass: AnyObject = NSClassFromString("REMSaveRequest"),
              let allocedClass = performPrivateSelector("alloc", on: saveRequestClass),
              let saveRequest = performPrivateSelector("initWithStore:", on: allocedClass, with: store),
              let changeItem = performPrivateSelector("updateReminder:", on: saveRequest, with: backingObject),
              let hashtagContext = performPrivateSelector("hashtagContext", on: changeItem) else {
            return
        }

        // NOTE: Remove all existing hashtags
        _ = performPrivateSelector("removeAllHashtags", on: hashtagContext)

        // NOTE: Add new tags. Abort save if we can't add them to prevent partial state
        if !newTags.isEmpty {
            let addHashtagSel = NSSelectorFromString("addHashtagWithType:name:")
            guard hashtagContext.responds(to: addHashtagSel),
                  let hashtagContextClass = object_getClass(hashtagContext),
                  let addMethod = class_getInstanceMethod(hashtagContextClass, addHashtagSel),
                  method_getNumberOfArguments(addMethod) == 4 else {
                return
            }
            let imp = method_getImplementation(addMethod)
            typealias AddFunc = @convention(c) (AnyObject, Selector, Int, AnyObject) -> Void
            let addFunc = unsafeBitCast(imp, to: AddFunc.self)
            for tag in newTags {
                addFunc(hashtagContext, addHashtagSel, 0, tag.name as NSString)
            }
        }

        // NOTE: Save to persist changes
        let saveSyncSel = NSSelectorFromString("saveSynchronouslyWithError:")
        if saveRequest.responds(to: saveSyncSel) {
            _ = saveRequest.perform(saveSyncSel, with: nil)
        }
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
}
