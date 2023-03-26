import Foundation

extension UserDefaults {
    func boolWithDefaultValueTrue(forKey key: String) -> Bool {
        guard self.object(forKey: key) != nil else {
            return true
        }
        return self.bool(forKey: key)
    }
}
