import Foundation

class SyncLogService {
    static let shared = SyncLogService()
    private init() {}

    private func logFileURL() -> URL? {
        guard let lib = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first else { return nil }
        let logsDir = lib.appendingPathComponent("Logs").appendingPathComponent("RemindersMenuBar", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: logsDir, withIntermediateDirectories: true)
        } catch { return nil }
        return logsDir.appendingPathComponent("sync.log")
    }

    func logSync(userId: String?, created: Int, updated: Int, linkedStories: Int, themed: Int, errors: [String]) {
        guard let url = logFileURL() else { return }
        let ts = ISO8601DateFormatter().string(from: Date())
        var lines: [String] = []
        lines.append("[\(ts)] uid=\(userId ?? "?") created=\(created) updated=\(updated) linkedStories=\(linkedStories) themed=\(themed) errors=\(errors.count)")
        for e in errors.prefix(5) { lines.append("  err: \(e)") }
        lines.append("")
        let text = lines.joined(separator: "\n")
        if let data = text.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: url.path) {
                if let handle = try? FileHandle(forWritingTo: url) {
                    handle.seekToEndOfFile()
                    handle.write(data)
                    try? handle.close()
                }
            } else {
                try? data.write(to: url)
            }
        }
    }
}

