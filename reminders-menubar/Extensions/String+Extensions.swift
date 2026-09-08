import Foundation

extension String {
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
    
    @available(macOS 12, *)
    func toDetectedLinkAttributedString() -> AttributedString {
        let range = NSRange(self.startIndex..., in: self)
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let attributedString = NSMutableAttributedString(string: self)

        for match in detector?.matches(in: self, options: [], range: range) ?? [] {
            if let url = match.url {
                attributedString.addAttribute(.link, value: url, range: match.range)
            }
        }

        return AttributedString(attributedString)
    }
}
