import EventKit

class PriorityParser {
    struct PriorityParserResult {
        private let range: NSRange
        let string: String
        let priority: EKReminderPriority?
        
        var highlightedText: RmbHighlightedTextField.HighlightedText {
            RmbHighlightedTextField.HighlightedText(range: range, color: .systemRed)
        }
        
        init() {
            self.range = NSRange()
            self.string = ""
            self.priority = nil
        }
        
        init(range: NSRange, string: String, priority: EKReminderPriority?) {
            self.range = range
            self.string = string
            self.priority = priority
        }
    }
    
    private init() {
        // This prevents others from using the default '()' initializer for this class.
    }
    
    static private func countExclamations(_ string: Substring) -> Int {
        var count = 0
        for char in string {
            if char == "!" {
                count += 1
            } else {
                break
            }
        }
        return count
    }
    
    static private func getPriority(_ count: Int) -> EKReminderPriority {
        switch count {
        case 3:
            return .high
        case 2:
            return .medium
        case 1:
            return .low
        default:
            return .none
        }
    }
    
    static func getPriorityMatch(from textString: String) -> PriorityParserResult? {
        let candidates = textString
            .split(separator: " ")
            .filter({ 1...3 ~= countExclamations($0) })
        
        guard let substringMatch = candidates.first else {
            return nil
        }
        let exclCount = countExclamations(substringMatch)
        let endPrefix = substringMatch.index(substringMatch.startIndex, offsetBy: exclCount)
        
        let range = NSRange(substringMatch.startIndex..<endPrefix, in: textString)
        
        return PriorityParserResult(
            range: range,
            string: String(repeating: "!", count: exclCount),
            priority: getPriority(exclCount))
    }
}
