import Foundation

extension Date {
    var isPast: Bool {
        return self.timeIntervalSinceNow < 0
    }
    
    static func currentNextHour(of date: Date = Date()) -> Date {
        let now = Date()
        let dateComponentsWithoutTime = Calendar.current.dateComponents([.year, .month, .day], from: date)
        let dateWithoutTime = Calendar.current.date(from: dateComponentsWithoutTime)!
        var hourComponent = Calendar.current.dateComponents([.hour], from: now)
        hourComponent.hour! += 1
        return Calendar.current.date(byAdding: hourComponent, to: dateWithoutTime)!
    }
    
    func relativeDateDescription(withTime showTimeDescription: Bool) -> String {
        let relativeDateFormatter = DateFormatter()
        relativeDateFormatter.timeStyle = showTimeDescription ? .short : .none
        relativeDateFormatter.dateStyle = .medium
        relativeDateFormatter.locale = rmbCurrentLocale()
        relativeDateFormatter.doesRelativeDateFormatting = true
        
        return relativeDateFormatter.string(from: self)
    }
    
    func dateComponentes(withTime: Bool) -> DateComponents {
        let components: Set<Calendar.Component> = withTime ? [.year, .month, .day, .hour, .minute] : [.year, .month, .day]
        return Calendar.current.dateComponents(components, from: self)
    }
}
