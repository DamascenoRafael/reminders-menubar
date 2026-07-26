import Foundation

class FlaggedParser {
    struct FlaggedParserResult {
        private let range: NSRange
        let string: String

        var highlightedText: RmbHighlightedTextField.HighlightedText {
            RmbHighlightedTextField.HighlightedText(range: range, color: RmbColor.flaggedHighlight.nsColor)
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

    static func getFlagged(from textString: String) -> FlaggedParserResult? {
        guard let substringMatch = textString
            .split(separator: " ")
            .first(where: { $0 == "!f" }) else {
                return nil
            }

        return FlaggedParserResult(
            range: NSRange(substringMatch.startIndex..<substringMatch.endIndex, in: textString),
            string: String(substringMatch)
        )
    }
}
