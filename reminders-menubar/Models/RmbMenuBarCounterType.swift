enum RmbMenuBarCounterType: String, Codable, CaseIterable {
    case due
    case today
    case filteredReminders
    case allReminders
    case disabled
    
    var title: String {
        switch self {
        case .due:
            return rmbLocalized(.showMenuBarDueCountOptionButton)
        case .today:
            return rmbLocalized(.showMenuBarTodayCountOptionButton)
        case .filteredReminders:
            return rmbLocalized(.showMenuBarFilteredRemindersCountOptionButton)
        case .allReminders:
            return rmbLocalized(.showMenuBarAllRemindersCountOptionButton)
        case .disabled:
            return rmbLocalized(.showMenuBarNoCountOptionButton)
        }
    }
}
