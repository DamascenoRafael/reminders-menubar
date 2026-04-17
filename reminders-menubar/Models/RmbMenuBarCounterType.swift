enum RmbMenuBarCounterType: String, Codable, CaseIterable {
    case due
    case today
    case allReminders
    case disabled
    
    var title: String {
        switch self {
        case .due:
            return rmbLocalized(.showMenuBarDueCountOption)
        case .today:
            return rmbLocalized(.showMenuBarTodayCountOption)
        case .allReminders:
            return rmbLocalized(.showMenuBarAllRemindersCountOption)
        case .disabled:
            return rmbLocalized(.showMenuBarNoCountOption)
        }
    }
}
