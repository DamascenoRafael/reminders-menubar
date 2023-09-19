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
                                    textDateResult: dateResult.textDateResult)
        }
        
        // NOTE: If the date is not adjusted we will return it unchanged.
        return dateResult
    }
    
    func getDate(from textString: String) -> DateParserResult? {
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
        
        let textDateResult = TextDateResult(range: match.range,
                                            string: textString.substring(in: match.range))
        let dateResult = DateParserResult(date: date,
                                          hasTime: hasTime,
                                          textDateResult: textDateResult)
        
        return adjustDateAccordingToNow(dateResult)
    }
}
