import Foundation

extension URL {
    var displayedUrl: String {
        var displayedUrlString = self.absoluteString
        if self.absoluteString.starts(with: "http"), let host = self.host {
            displayedUrlString = host
        }
        return displayedUrlString.replacingOccurrences(of: "^www.", with: "", options: .regularExpression)
    }
}
