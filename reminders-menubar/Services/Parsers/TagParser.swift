import Foundation

class TagParser {
    struct TextTagResult {
        private let range: NSRange
        let string: String
        let tag: Tag

        var highlightedText: RmbHighlightedTextField.HighlightedText {
            RmbHighlightedTextField.HighlightedText(range: range, color: RmbColor.tagHighlight.nsColor)
        }

        init(range: NSRange, string: String, tag: Tag) {
            self.range = range
            self.string = string
            self.tag = tag
        }
    }

    private var knownTags: [Tag] = []

    static private let validInitialChars: Set<String?> = ["#"]

    static let shared = TagParser()

    private init() {
        // This prevents others from using the default '()' initializer for this class.
    }

    static func updateShared(with tags: [Tag]) {
        TagParser.shared.knownTags = tags
    }

    static func resolvedTagName(_ tagName: String) -> String {
        let target = Tag(tagName)
        return TagParser.shared.knownTags.first(where: { $0 == target })?.name ?? tagName
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
            results.append(TextTagResult(range: range, string: String(word), tag: Tag(tagName)))
        }

        return results
    }

    static func autoCompleteSuggestions(_ typingWord: String) -> [String] {
        let lowercasedTypingWord = typingWord.lowercased()
        let maxSuggestions = 3
        let matches = TagParser.shared.knownTags
            .filter({ $0.name.count > typingWord.count && $0.name.lowercased().hasPrefix(lowercasedTypingWord) })
            .sorted(by: { $0.name.count < $1.name.count })
            .prefix(maxSuggestions)
        return matches.map({ typingWord + $0.name.dropFirst(typingWord.count) })
    }
}
