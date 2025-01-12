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
    
    var fullRange: NSRange {
        return NSRange(location: 0, length: endIndex.utf16Offset(in: self))
    }
}
