import Foundation

struct Tag: Hashable, Equatable, Identifiable, Comparable, Codable {
    let id: String
    let name: String

    init(_ name: String) {
        self.id = name.lowercased()
        self.name = name
    }

    static func == (lhs: Tag, rhs: Tag) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func < (lhs: Tag, rhs: Tag) -> Bool {
        lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.init(try container.decode(String.self))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(name)
    }
}
