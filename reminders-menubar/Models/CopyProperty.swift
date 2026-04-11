import Foundation

enum CopyProperty: String, Codable, CaseIterable {
    case title
    case notes
    case date
    case url
    case priority
    case list

    static var defaultOptions: [CopyPropertyOption] {
        let enabledByDefault: Set<CopyProperty> = [.title, .notes, .date, .url]
        return allCases.map {
            CopyPropertyOption(property: $0, isEnabled: enabledByDefault.contains($0))
        }
    }

    static func reconciledOptions(from saved: [CopyPropertyOption]) -> [CopyPropertyOption] {
        let savedProperties = Set(saved.map { $0.property })
        let validOptions = saved.filter { allCases.contains($0.property) }
        let newOptions = allCases
            .filter { !savedProperties.contains($0) }
            .map { CopyPropertyOption(property: $0, isEnabled: false) }
        return validOptions + newOptions
    }

    var displayName: String {
        switch self {
        case .title:
            return rmbLocalized(.copyPropertyTitle)
        case .notes:
            return rmbLocalized(.copyPropertyNotes)
        case .date:
            return rmbLocalized(.copyPropertyDate)
        case .priority:
            return rmbLocalized(.copyPropertyPriority)
        case .list:
            return rmbLocalized(.copyPropertyList)
        case .url:
            return rmbLocalized(.copyPropertyUrl)
        }
    }
}

struct CopyPropertyOption: Codable, Identifiable, Equatable {
    var id: String { property.rawValue }
    let property: CopyProperty
    var isEnabled: Bool
}
