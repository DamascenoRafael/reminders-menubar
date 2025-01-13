import Foundation

extension String {
    subscript(safe offset: Int) -> String? {
        offset >= 0 && offset < count ? String(self[index(startIndex, offsetBy: offset)]) : nil
    }
    
    func substring(in range: NSRange) -> String {
        let start = self.index(self.startIndex, offsetBy: range.lowerBound)
        let end = self.index(self.startIndex, offsetBy: range.upperBound)
        let subString = self[start..<end]
        return String(subString)
    }
    
    var fullRange: NSRange {
        return NSRange(location: 0, length: self.count)
    }
    
    func toDetectedLinkAttributedString() -> String {
        let range = NSRange(self.startIndex..., in: self)
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        guard let matches = detector?.matches(in: self, options: [], range: range), !matches.isEmpty else {
            return self
        }
        
        let attributedString = NSMutableAttributedString(string: self)
        for match in matches {
            if let url = match.url {
                attributedString.addAttribute(.link, value: url, range: match.range)
            }
        }
        
        return attributedString.string
    }
}
