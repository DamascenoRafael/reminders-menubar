import Foundation

struct Release: Decodable {
    let version: String
    
    enum CodingKeys: String, CodingKey {
        case version = "tag_name"
    }
}

extension Release {
  static func == (lhs: Release, rhs: Release) -> Bool {
    return lhs.version.compare(rhs.version, options: .numeric) == .orderedSame
  }

  static func < (lhs: Release, rhs: Release) -> Bool {
    return lhs.version.compare(rhs.version, options: .numeric) == .orderedAscending
  }

  static func > (lhs: Release, rhs: Release) -> Bool {
    return lhs.version.compare(rhs.version, options: .numeric) == .orderedDescending
  }
}
