import Foundation

enum RmbMenuBarPreviewTimeAhead: String, Codable, CaseIterable {
    case atTime
    case oneMinute
    case fiveMinutes
    case tenMinutes
    case fifteenMinutes
    case thirtyMinutes
    case oneHour

    var timeInterval: TimeInterval {
        switch self {
        case .atTime:
            return 0
        case .oneMinute:
            return 1 * 60
        case .fiveMinutes:
            return 5 * 60
        case .tenMinutes:
            return 10 * 60
        case .fifteenMinutes:
            return 15 * 60
        case .thirtyMinutes:
            return 30 * 60
        case .oneHour:
            return 60 * 60
        }
    }

    var title: String {
        switch self {
        case .atTime:
            return rmbLocalized(.menuBarPreviewTimeAheadAtTimeOption)
        case .oneMinute:
            return rmbLocalized(.menuBarPreviewTimeAheadMinOption, arguments: 1)
        case .fiveMinutes:
            return rmbLocalized(.menuBarPreviewTimeAheadMinOption, arguments: 5)
        case .tenMinutes:
            return rmbLocalized(.menuBarPreviewTimeAheadMinOption, arguments: 10)
        case .fifteenMinutes:
            return rmbLocalized(.menuBarPreviewTimeAheadMinOption, arguments: 15)
        case .thirtyMinutes:
            return rmbLocalized(.menuBarPreviewTimeAheadMinOption, arguments: 30)
        case .oneHour:
            return rmbLocalized(.menuBarPreviewTimeAheadHourOption, arguments: 1)
        }
    }
}
