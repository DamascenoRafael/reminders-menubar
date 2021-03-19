import Foundation

extension Calendar {
    func endOfDay(for date: Date) -> Date? {
        var dateComponents = DateComponents()
        dateComponents.day = 1
        dateComponents.second = -1
        return self.date(byAdding: dateComponents, to: self.startOfDay(for: date))
    }
}
