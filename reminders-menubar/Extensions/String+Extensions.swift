import Foundation

extension String {
    private static let linkDetector = try? NSDataDetector(
        types: NSTextCheckingResult.CheckingType.link.rawValue
    )

    subscript(safe offset: Int) -> String? {
        guard offset >= 0, offset < endIndex.utf16Offset(in: self) else {
            return nil
        }
        
        let offsetIndex = Index(utf16Offset: offset, in: self)
        return String(self[offsetIndex])
    }
    
    func substring(in nsRange: NSRange) -> String {
        guard let range = Range(nsRange, in: self) else {
            return ""
        }
        
        return String(self[range])
    }
    
    func toDetectedLinkAttributedString() -> AttributedString {
        let attributedString = NSMutableAttributedString(string: self)

        for match in detectedLinkMatches() {
            if let url = match.url {
                attributedString.addAttribute(.link, value: url, range: match.range)
            }
        }

        return AttributedString(attributedString)
    }

    func detectedUrls() -> [URL] {
        detectedLinkMatches().compactMap(\.url)
    }

    private func detectedLinkMatches() -> [NSTextCheckingResult] {
        let range = NSRange(startIndex..., in: self)
        return Self.linkDetector?.matches(in: self, options: [], range: range) ?? []
    }
}
