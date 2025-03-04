import Foundation

extension Calendar {
    func endOfDay(for date: Date) -> Date? {
        var dateComponents = DateComponents()
        dateComponents.day = 1
        dateComponents.second = -1
        return self.date(byAdding: dateComponents, to: self.startOfDay(for: date))
    }

    func daysBetween(_ startDate: Date, and endDate: Date) -> Int {
        let dateComponents = Calendar.current.dateComponents(
            [.day],
            from: startOfDay(for: startDate),
            to: startOfDay(for: endDate)
        )
        return dateComponents.day ?? 0
    }
}
