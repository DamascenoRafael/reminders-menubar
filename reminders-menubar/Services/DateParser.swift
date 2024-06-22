import Foundation

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
    
    private func adjustedDate(_ date: Date, _ isTimeOnly: Bool, _ matchString: String) -> Date? {
        // NOTE: Date will be adjusted only if it is in the past.
        guard date.isPast else {
            return date
        }
        
        let cal = Calendar.current
        
        // Fetch the year that the match specifies
        let matchedYear = String(date.dateComponents(withTime: false).year!)
        
        // NOTE: If the date is set to a day in the current year, but it's past that day, then we assume it's next year.
        // For example "on February 2nd" - when it's already March.
        if date.isThisYear && !matchString.contains(matchedYear)
            && !date.isToday
            && !date.isYesterday
            && !date.isDayBeforeYesterday {
            return Date.nextYear(of: date)
        }
        
        // NOTE: If the time appears in the past, we assume it's the next day.
        // For example "on 8am" – but it's already noon.
        if isTimeOnly {
            return cal.date(byAdding: .day, value: 1, to: date)
        }
        return date
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
        let textDateResult = TextDateResult(range: match.range,
                                            string: textString.substring(in: match.range))
        
        debugPrint(date, isTimeOnly, textDateResult)
        
        let adjustedDate = adjustedDate(date, isTimeOnly, textString)!
        
        return DateParserResult(date: adjustedDate,
                                hasTime: hasTime,
                                isTimeOnly: isTimeOnly,
                                textDateResult: textDateResult)
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
