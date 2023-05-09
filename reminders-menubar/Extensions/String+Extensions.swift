import Foundation

extension String {
    func substring(in range: NSRange) -> String {
        let start = self.index(self.startIndex, offsetBy: range.lowerBound)
        let end = self.index(self.startIndex, offsetBy: range.upperBound)
        let subString = self[start..<end]
        return String(subString)
    }
    
    var fullRange: NSRange {
        return NSRange(location: 0, length: self.count)
    }
}
