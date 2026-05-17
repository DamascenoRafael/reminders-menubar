import Foundation

class TagParser {
    struct TextTagResult {
        private let range: NSRange
        let string: String
        let tagName: String

        var highlightedText: RmbHighlightedTextField.HighlightedText {
            RmbHighlightedTextField.HighlightedText(range: range, color: .systemPurple)
        }

        init(range: NSRange, string: String, tagName: String) {
            self.range = range
            self.string = string
            self.tagName = tagName
        }
    }

    private var knownTagNames: [String] = []
    private var originalCasingByLowercased: [String: String] = [:]

    static private let validInitialChars: Set<String?> = ["#"]

    static let shared = TagParser()

    private init() {
        // This prevents others from using the default '()' initializer for this class.
    }

    static func updateShared(with tags: [String]) {
        TagParser.shared.knownTagNames = tags.map({ $0.lowercased() })
        TagParser.shared.originalCasingByLowercased = Dictionary(
            tags.map { ($0.lowercased(), $0) },
            uniquingKeysWith: { first, _ in first }
        )
    }

    static func resolvedTagName(_ tagName: String) -> String {
        return TagParser.shared.originalCasingByLowercased[tagName.lowercased()] ?? tagName
    }

    static private let allowedTagCharacters: CharacterSet = {
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-_")
        return allowed
    }()

    static func sanitizedTagName(_ raw: String) -> String {
        raw.precomposedStringWithCanonicalMapping.unicodeScalars
            .filter { allowedTagCharacters.contains($0) }
            .reduce(into: "") { $0.unicodeScalars.append($1) }
    }

    static func isInitialCharValid(_ char: String?) -> Bool {
        return validInitialChars.contains(char)
    }

    static func getTags(from textString: String) -> [TextTagResult] {
        let words = textString.split(separator: " ")
        var results: [TextTagResult] = []

        for word in words {
            let prefix = String(word.prefix(1))
            guard TagParser.isInitialCharValid(prefix) else {
                continue
            }

            let rawTagName = String(word.dropFirst())
            let sanitized = sanitizedTagName(rawTagName)
            guard !sanitized.isEmpty else {
                continue
            }

            let tagName = resolvedTagName(sanitized)
            let range = NSRange(word.startIndex..<word.endIndex, in: textString)
            results.append(TextTagResult(range: range, string: String(word), tagName: tagName))
        }

        return results
    }

    static func autoCompleteSuggestions(_ typingWord: String) -> [String] {
        let lowercasedTypingWord = typingWord.lowercased()
        let maxSuggestions = 3
        let matches = TagParser.shared.knownTagNames
            .filter({ $0.count > lowercasedTypingWord.count && $0.hasPrefix(lowercasedTypingWord) })
            .sorted(by: { $0.count < $1.count })
            .prefix(maxSuggestions)
        return matches.map({ typingWord + $0.dropFirst(typingWord.count) })
    }
}
