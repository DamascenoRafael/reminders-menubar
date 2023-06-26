import EventKit

class CalendarParser {
    struct TextCalendarResult {
        private let range: NSRange
        let string: String
        let calendar: EKCalendar?
        
        var highlightedText: RmbHighlightedTextField.HighlightedText {
            RmbHighlightedTextField.HighlightedText(range: range, color: calendar?.color ?? .white)
        }
        
        init() {
            self.range = NSRange()
            self.string = ""
            self.calendar = nil
        }
        
        init(range: NSRange, string: String, calendar: EKCalendar?) {
            self.range = range
            self.string = string
            self.calendar = calendar
        }
    }
    
    private var calendarsByTitle: [String: EKCalendar] = [:]
    private var simplifiedCalendarTitles: [String] = []
    
    static private(set) var shared = CalendarParser()
    
    private init() {
        // This prevents others from using the default '()' initializer for this class.
    }
    
    static func updateShared(with calendars: [EKCalendar]) -> Bool? {
        CalendarParser.shared.calendarsByTitle = calendars
            .reduce(into: [String: EKCalendar](), { partialResult, calendar in
                let simplifiedTitle = calendar.title.lowercased().replacingOccurrences(of: " ", with: "-")
                partialResult[simplifiedTitle] = calendar
            })
        CalendarParser.shared.simplifiedCalendarTitles = Array(CalendarParser.shared.calendarsByTitle.keys)
        
        return nil
    }
    
    static func isInitialCharValid(_ char: String?) -> Bool {
        let validChars: [String?] = ["/", "@"]
        return validChars.contains(char)
    }
    
    static func getCalendar(from textString: String) -> TextCalendarResult? {
        let candidates = textString.split(separator: " ").filter({
            CalendarParser.isInitialCharValid(String($0.prefix(1)))
        })
        
        guard let substringMatch = candidates.first(
            where: {
                let title = $0.dropFirst().lowercased()
                return CalendarParser.shared.calendarsByTitle[title] != nil
            }
        ) else {
            return nil
        }
        
        let range = NSRange(substringMatch.startIndex..<substringMatch.endIndex, in: textString)
        let calendar = CalendarParser.shared.calendarsByTitle[substringMatch.dropFirst().lowercased()]
        return TextCalendarResult(range: range, string: String(substringMatch), calendar: calendar)
    }
    
    static func autoCompleteSuggestions(_ typingWord: String) -> [String] {
        let lowercasedTypingWord = typingWord.lowercased()
        let maxSuggestions = 3
        let matches = CalendarParser.shared.simplifiedCalendarTitles
            .filter({ $0.count > lowercasedTypingWord.count && $0.hasPrefix(lowercasedTypingWord) })
            .sorted(by: { $0.count < $1.count })
            .prefix(maxSuggestions)
        return matches.map({ typingWord + $0.dropFirst(typingWord.count) })
    }
}
