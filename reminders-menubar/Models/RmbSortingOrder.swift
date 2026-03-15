enum RmbSortingOrder: String, Codable, CaseIterable {
    case defaultOrder
    case newestFirst
    case oldestFirst

    var title: String {
        switch self {
        case .defaultOrder:
            return rmbLocalized(.reminderSortingDefaultOrderOption)
        case .newestFirst:
            return rmbLocalized(.reminderSortingNewestFirstOption)
        case .oldestFirst:
            return rmbLocalized(.reminderSortingOldestFirstOption)
        }
    }

    var note: String {
        switch self {
        case .defaultOrder:
            return rmbLocalized(.reminderSortingDefaultOrderNote)
        case .newestFirst:
            return rmbLocalized(.reminderSortingNewestFirstNote)
        case .oldestFirst:
            return rmbLocalized(.reminderSortingOldestFirstNote)
        }
    }
}
