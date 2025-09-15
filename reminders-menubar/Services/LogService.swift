import Foundation

enum LogCategory: String, CaseIterable {
    case app = "App"
    case auth = "Auth"
    case sync = "Sync"
    case crud = "CRUD"
    case network = "Network"
}

enum LogLevel: String {
    case debug = "DEBUG"
    case info = "INFO"
    case warn = "WARN"
    case error = "ERROR"
}

struct LogEntry: Identifiable {
    let id = UUID()
    let timestamp: Date
    let level: LogLevel
    let category: LogCategory
    let message: String
}

@MainActor
class LogService: ObservableObject {
    static let shared = LogService()
    private init() {}

    @Published private(set) var entries: [LogEntry] = []
    private let maxEntries = 1000

    func log(_ level: LogLevel = .info, _ category: LogCategory, _ message: String) {
        let entry = LogEntry(timestamp: Date(), level: level, category: category, message: message)
        entries.append(entry)
        if entries.count > maxEntries { entries.removeFirst(entries.count - maxEntries) }
        #if DEBUG
        print("[\(entry.level.rawValue)] [\(entry.category.rawValue)] \(entry.message)")
        #endif
    }

    func clear() { entries.removeAll() }
}

