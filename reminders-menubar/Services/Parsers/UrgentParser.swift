import Foundation

class UrgentParser {
    struct UrgentParserResult {
        private let range: NSRange
        let string: String

        var highlightedText: RmbHighlightedTextField.HighlightedText {
            RmbHighlightedTextField.HighlightedText(range: range, color: RmbColor.urgentHighlight.nsColor)
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

    private init() {}

    static func getUrgent(from textString: String) -> UrgentParserResult? {
        guard let substringMatch = textString
            .split(separator: " ")
            .first(where: { $0 == "!u" }) else {
                return nil
            }

        return UrgentParserResult(
            range: NSRange(substringMatch.startIndex..<substringMatch.endIndex, in: textString),
            string: String(substringMatch)
        )
    }
}
