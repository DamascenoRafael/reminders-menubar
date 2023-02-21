import Foundation

class DateParser {
    static let instance = DateParser()
    
    private let detector: NSDataDetector?
    
    struct DateParseResult {
        let date: Date
        let hasTime: Bool
        let dateRelatedWords: String
    }
    
    private init() {
        // This prevents others from using the default '()' initializer for this class.
        let types: NSTextCheckingResult.CheckingType = [.date]
        detector = try? NSDataDetector(types: types.rawValue)
    }
    
    private func adjustDateAccordingToNow(_ dateResult: DateParseResult) -> DateParseResult? {
        // If the date it's not in the current year, then it's not valid
        if dateResult.date.isPastYear {
            return nil
        }
        
        // If only the time is defined, and it's past the current time, then we assume it's for the next day
        if dateResult.date.isToday
            && dateResult.hasTime
            && dateResult.date.isPast {
            return DateParseResult(date: Date.nextDay(of: dateResult.date),
                                   hasTime: dateResult.hasTime,
                                   dateRelatedWords: dateResult.dateRelatedWords)
        }
        
        // If the day it's defined, and it's from the same year as the current date, but it's in the past,
        // then we assume it's for the next year
        if dateResult.date < Date() {
            return DateParseResult(date: Date.nextYear(of: dateResult.date),
                                   hasTime: dateResult.hasTime,
                                   dateRelatedWords: dateResult.dateRelatedWords)
        }
        return dateResult
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
        
        let stringWithoutDateRelatedText = textString.substringRange(match.range)
        let dateResult = DateParseResult(date: date, hasTime: hasTime, dateRelatedWords: stringWithoutDateRelatedText)
        
        return adjustDateAccordingToNow(dateResult)
    }
}
