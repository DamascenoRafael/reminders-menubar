import Foundation

class DateParser {
    static let shared = DateParser()
    
    private let detector: NSDataDetector?
    
    struct DateParseResult {
        let date: Date
        let hasTime: Bool
        let dateRelatedString: String
    }
    
    private init() {
        // This prevents others from using the default '()' initializer for this class.
        let types: NSTextCheckingResult.CheckingType = [.date]
        detector = try? NSDataDetector(types: types.rawValue)
    }
    
    private func adjustDateAccordingToNow(_ dateResult: DateParseResult) -> DateParseResult? {
        // NOTE: Date will be adjusted only if it is in the past.
        let dateIsPastAndHasTime = dateResult.hasTime && dateResult.date.isPast
        let dateIsPastAndHasNoTime = !dateResult.hasTime && dateResult.date.isPast && !dateResult.date.isToday
        guard dateIsPastAndHasTime || dateIsPastAndHasNoTime else {
            return dateResult
        }
        
        // NOTE: If the time is set for today, but it's past time today, then we assume it's next day.
        // "Do something at 9am" - when it's already 2pm.
        if dateResult.hasTime && dateResult.date.isToday {
            return DateParseResult(date: .nextDay(of: dateResult.date),
                                   hasTime: dateResult.hasTime,
                                   dateRelatedString: dateResult.dateRelatedString)
        }
        
        // NOTE: If the date is set to a day in the current year, but it's past that day, then we assume it's next year.
        // "Do something on February 2nd" - when it's already March.
        if dateResult.date.isThisYear {
            return DateParseResult(date: .nextYear(of: dateResult.date),
                                   hasTime: dateResult.hasTime,
                                   dateRelatedString: dateResult.dateRelatedString)
        }
        
        // NOTE: If the date is not adjusted we prefer not to suggest a date that is in the past.
        return nil
    }
    
    func getDate(from textString: String) -> DateParseResult? {
        let range = NSRange(textString.startIndex..., in: textString)
        
        let matches = detector?.matches(in: textString, options: [], range: range)
        guard let match = matches?.first, let date = match.date else {
            return nil
        }
        
        var hasTime = false
        let timeIsSignificantKey = "timeIsSignificant"
        if match.responds(to: NSSelectorFromString(timeIsSignificantKey)) {
            hasTime = match.value(forKey: timeIsSignificantKey) as? Bool ?? false
        }
        
        let dateRelatedString = textString.substringRange(match.range)
        let dateResult = DateParseResult(date: date, hasTime: hasTime, dateRelatedString: dateRelatedString)
        
        return adjustDateAccordingToNow(dateResult)
    }
}
