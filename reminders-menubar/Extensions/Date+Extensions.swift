import Foundation

extension Date {
    var isPast: Bool {
        return self.timeIntervalSinceNow < 0
    }
    
    var isToday: Bool {
        return Calendar.current.isDateInToday(self)
    }
    
    var isYesterday: Bool {
        return Calendar.current.isDateInYesterday(self)
    }
    
    var isDayBeforeYesterday: Bool {
        let dayBeforeYesterday = Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? self
        return self.isSameDay(as: dayBeforeYesterday)
    }
                                                                   
    var isThisYear: Bool {
        return Calendar.current.isDate(self, equalTo: Date(), toGranularity: .year)
    }
    
    var elapsedTimeInterval: TimeInterval {
        return Date().timeIntervalSince(self)
    }
    
    static func nextExactHour(of date: Date = Date(), allowDayChange: Bool = false) -> Date {
        let today = Date()
        let todayNextHour = Calendar.current.date(byAdding: .hour, value: 1, to: today)!
        let isNextHourChangingDay = !todayNextHour.isToday
        
        var hourComponent = Calendar.current.dateComponents([.hour], from: today)
        if allowDayChange || !isNextHourChangingDay {
            hourComponent.hour! += 1
        }
        
        let dateWithoutTime = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: date)!
        return Calendar.current.date(byAdding: hourComponent, to: dateWithoutTime)!
    }
    
    static func nextYear(of date: Date = Date()) -> Date {
        return Calendar.current.date(byAdding: .year, value: 1, to: date) ?? date
    }
    
    func isSameDay(as otherDate: Date) -> Bool {
        return Calendar.current.isDate(self, inSameDayAs: otherDate)
    }
    
    func relativeDateDescription(withTime showTimeDescription: Bool) -> String {
        let relativeDateFormatter = DateFormatter()
        relativeDateFormatter.locale = rmbCurrentLocale()
        relativeDateFormatter.doesRelativeDateFormatting = true
        
        if isThisYear {
            // Short format without year: "Dec 16" or "Dec 16, 3:00 PM"
            relativeDateFormatter.dateFormat = showTimeDescription
                ? DateFormatter.dateFormat(fromTemplate: "MMMd jmm", options: 0, locale: rmbCurrentLocale())
                : DateFormatter.dateFormat(fromTemplate: "MMMd", options: 0, locale: rmbCurrentLocale())
        } else {
            relativeDateFormatter.dateStyle = .medium
            relativeDateFormatter.timeStyle = showTimeDescription ? .short : .none
        }
        
        return relativeDateFormatter.string(from: self)
    }
    
    func dateComponents(withTime: Bool) -> DateComponents {
        var components: Set<Calendar.Component> = [.calendar, .era, .year, .month, .day]
        if withTime {
            components.formUnion([.timeZone, .hour, .minute, .second])
        }
        return Calendar.current.dateComponents(components, from: self)
    }
}
