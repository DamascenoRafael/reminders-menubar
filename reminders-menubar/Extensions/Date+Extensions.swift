import Foundation

extension Date {
    var isPast: Bool {
        return self.timeIntervalSinceNow < 0
    }
    
    var isToday: Bool {
        let todayDateComponents = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        let inputDateComponents = Calendar.current.dateComponents([.year, .month, .day], from: self)
        return inputDateComponents.day == todayDateComponents.day
            && inputDateComponents.month == todayDateComponents.month
            && inputDateComponents.year == todayDateComponents.year
    }
                                                                   
    var isThisYear: Bool {
        let todayDateComponents = Calendar.current.dateComponents([.year], from: Date())
        let inputDateComponents = Calendar.current.dateComponents([.year], from: self)
        return inputDateComponents.year! == todayDateComponents.year!
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
        var dateComponents = DateComponents()
        dateComponents.year = 1
        let newDate = Calendar.current.date(byAdding: dateComponents, to: date)!
        return newDate
    }
    
    static func nextDay(of date: Date = Date()) -> Date {
        var dateComponents = DateComponents()
        dateComponents.day = 1
        let newDate = Calendar.current.date(byAdding: dateComponents, to: date)!
        return newDate
    }
    
    func relativeDateDescription(withTime showTimeDescription: Bool) -> String {
        let relativeDateFormatter = DateFormatter()
        relativeDateFormatter.timeStyle = showTimeDescription ? .short : .none
        relativeDateFormatter.dateStyle = .medium
        relativeDateFormatter.locale = rmbCurrentLocale()
        relativeDateFormatter.doesRelativeDateFormatting = true
        
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
