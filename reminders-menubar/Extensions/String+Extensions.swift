import Foundation

extension String {
    subscript(safe offset: Int) -> String? {
        offset >= 0 && offset < count ? String(self[index(startIndex, offsetBy: offset)]) : nil
    }
    
    func substring(in range: NSRange) -> String? {
        guard range.location != NSNotFound, range.location >= 0, range.length >= 0 else {
            return nil
        }
        
        let stringLength = self.count
        let lowerBound = range.lowerBound
        let upperBound = range.upperBound
        
        guard lowerBound < stringLength, upperBound <= stringLength else {
            return nil
        }
        
        let start = self.index(self.startIndex, offsetBy: lowerBound)
        let end = self.index(self.startIndex, offsetBy: upperBound)
        let subString = self[start..<end]
        return String(subString)
    }
    
    var fullRange: NSRange {
        return NSRange(location: 0, length: self.count)
    }
}
