import Foundation

struct TextDateResult {
    var range: NSRange
    var string: String
}

class DateParser {
    static let shared = DateParser()
    
    private let detector: NSDataDetector?
    
    struct TextDateResult {
        private let range: NSRange
        let string: String
        
        var highlightedText: RmbHighlightedTextField.HighlightedText {
            RmbHighlightedTextField.HighlightedText(range: range, color: .systemBlue)
        }
        
        init() {
            self.range = NSRange()
            self.string = ""
        }
        
        init(range: NSRange, string: String) {
            self.range = range
            self.string = string
        }
    }
    
    struct DateParserResult {
        let date: Date
        let hasTime: Bool
        let isTimeOnly: Bool
        let textDateResult: TextDateResult
    }
    
    private init() {
        // This prevents others from using the default '()' initializer for this class.
        let types: NSTextCheckingResult.CheckingType = [.date]
        detector = try? NSDataDetector(types: types.rawValue)
    }
    
    private func adjustDateAccordingToNow(_ dateResult: DateParserResult) -> DateParserResult? {
        // NOTE: Date will be adjusted only if it is in the past further than the day before yesterday.
        guard dateResult.date.isPast
                && !dateResult.date.isToday
                && !dateResult.date.isYesterday
                && !dateResult.date.isDayBeforeYesterday else {
            return dateResult
        }
        
        // NOTE: If the date is set to a day in the current year, but it's past that day, then we assume it's next year.
        // "Do something on February 2nd" - when it's already March.
        if dateResult.date.isThisYear {
            return DateParserResult(date: .nextYear(of: dateResult.date),
                                    hasTime: dateResult.hasTime,
                                    isTimeOnly: dateResult.isTimeOnly,
                                    textDateResult: dateResult.textDateResult)
        }
        
        // NOTE: If the date is not adjusted we will return it unchanged.
        return dateResult
    }
    
    private func isTimeSignificant(in match: NSTextCheckingResult) -> Bool {
        let timeIsSignificantKey = "timeIsSignificant"
        if match.responds(to: NSSelectorFromString(timeIsSignificantKey)) {
            return match.value(forKey: timeIsSignificantKey) as? Bool ?? false
        }
        return false
    }
    
    private func isTimeOnlyResult(in match: NSTextCheckingResult) -> Bool {
        let underlyingResultKey = "underlyingResult"
        if match.responds(to: NSSelectorFromString(underlyingResultKey)) {
            let underlyingResult = match.value(forKey: underlyingResultKey)
            let description = underlyingResult.debugDescription
            return description.contains("Time") && !description.contains("Date")
        }
        return false
    }
    
    func getDate(from textString: String) -> DateParserResult? {
        let range = NSRange(textString.startIndex..., in: textString)
        
        let matches = detector?.matches(in: textString, options: [], range: range)
        guard let match = matches?.first, let date = match.date else {
            return nil
        }
        
        let hasTime = isTimeSignificant(in: match)
        let isTimeOnly = isTimeOnlyResult(in: match)
        
        let textDateResult: TextDateResult
        if let substring = textString.substring(in: match.range) {
            textDateResult = TextDateResult(range: match.range, string: substring)
        } else {
            textDateResult = TextDateResult(range: NSRange(location: 0, length: 0), string: "")
        }
        
        let dateResult = DateParserResult(date: date,
                                          hasTime: hasTime,
                                          isTimeOnly: isTimeOnly,
                                          textDateResult: textDateResult)
        
        return adjustDateAccordingToNow(dateResult)
    }
    
    func getTimeOnly(from textString: String, on date: Date) -> DateParserResult? {
        guard let dateResult = getDate(from: textString),
              dateResult.date.isSameDay(as: date) || dateResult.isTimeOnly,
              dateResult.hasTime else {
            return nil
        }
        
        return dateResult
    }
}
