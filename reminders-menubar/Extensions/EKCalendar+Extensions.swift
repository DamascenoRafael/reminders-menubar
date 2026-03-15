import EventKit

extension EKCalendar {
    private var listBackingObject: AnyObject? {
        let backingObjectSelector = NSSelectorFromString("backingObject")
        let listSelector = NSSelectorFromString("_list")

        guard self.responds(to: backingObjectSelector),
              let unmanagedBackingObject = self.perform(backingObjectSelector) else {
            return nil
        }

        let backingObject = unmanagedBackingObject.takeUnretainedValue()
        guard backingObject.responds(to: listSelector),
              let unmanagedList = backingObject.perform(listSelector) else {
            return nil
        }

        return unmanagedList.takeUnretainedValue()
    }

    // NOTE: This is a workaround to access the display ordering of reminders in a list.
    // This property is not accessible through the conventional API.
    var reminderOrdering: [String]? {
        guard let listObject = listBackingObject else {
            return nil
        }

        let orderingKey = "reminderIDsOrdering"
        guard (listObject as AnyObject).responds(to: NSSelectorFromString(orderingKey)),
              let orderedSet = listObject.value(forKey: orderingKey) as? NSOrderedSet else {
            return nil
        }

        let uuidSelector = NSSelectorFromString("uuid")
        var ordering: [String] = []
        for element in orderedSet {
            let obj = element as AnyObject
            guard obj.responds(to: uuidSelector),
                  let unmanagedUuid = obj.perform(uuidSelector),
                  let uuid = unmanagedUuid.takeUnretainedValue() as? UUID else {
                continue
            }
            ordering.append(uuid.uuidString)
        }

        return ordering.isEmpty ? nil : ordering
    }
}
