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
    
    private let titleCalendarDictionary: [String: EKCalendar]
    
    init(calendars: [EKCalendar]) {
        titleCalendarDictionary = calendars.reduce(into: [String: EKCalendar](), { partialResult, calendar in
            let simplifiedTitle = calendar.title.lowercased().replacingOccurrences(of: " ", with: "-")
            partialResult[simplifiedTitle] = calendar
        })
    }
    
    func getCalendar(from textString: String) -> TextCalendarResult? {
        let candidates = textString.split(separator: " ").filter({ $0.hasPrefix("@") || $0.hasPrefix("/") })
        
        guard let substringMatch = candidates.first(
            where: {
                let title = $0.dropFirst().lowercased()
                return titleCalendarDictionary[title] != nil
            }
        ) else {
            return nil
        }
        
        let range = NSRange(substringMatch.startIndex..<substringMatch.endIndex, in: textString)
        let calendar = titleCalendarDictionary[substringMatch.dropFirst().lowercased()]
        return TextCalendarResult(range: range, string: String(substringMatch), calendar: calendar)
    }
}
