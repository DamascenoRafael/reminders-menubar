import Foundation

extension URL {
    var displayedUrl: String {
        if self.absoluteString.starts(with: "http") {
            return self.host ?? self.absoluteString
        }
        return self.absoluteString
    }
}
