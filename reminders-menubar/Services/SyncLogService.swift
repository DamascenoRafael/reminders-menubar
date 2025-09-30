import Foundation

import os.log
#if canImport(AppKit)
import AppKit
#endif

class SyncLogService {
    static let shared = SyncLogService()
    private init() {}

    enum SyncDirection: String {
        case toReminders
        case toBob
        case diagnostics
    }

    private func logFileURL() -> URL? {
        guard let lib = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first else { return nil }
        let logsDir = lib.appendingPathComponent("Logs").appendingPathComponent("RemindersMenuBar", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: logsDir, withIntermediateDirectories: true)
        } catch { return nil }
        return logsDir.appendingPathComponent("sync.log")
    }

    private func rotateIfNeeded(_ url: URL) {
        // Simple size-based rotation at ~1 MiB
        let limit: UInt64 = 1 * 1024 * 1024
        if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
           let size = attrs[.size] as? UInt64, size > limit {
            let ts = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
            let rotated = url.deletingLastPathComponent().appendingPathComponent("sync-\(ts).log")
            _ = try? FileManager.default.moveItem(at: url, to: rotated)
        }
    }

    private func append(lines: [String]) {
        guard let url = logFileURL() else { return }
        rotateIfNeeded(url)
        let text = lines.joined(separator: "\n") + "\n"
        guard let data = text.data(using: .utf8) else { return }
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

    func logSync(userId: String?, created: Int, updated: Int, linkedStories: Int, themed: Int, errors: [String]) {
        let ts = ISO8601DateFormatter().string(from: Date())
        var lines: [String] = []
        lines.append("[\(ts)] uid=\(userId ?? "?") created=\(created) updated=\(updated) linkedStories=\(linkedStories) themed=\(themed) errors=\(errors.count)")
        for errorMessage in errors.prefix(5) { lines.append("  err: \(errorMessage)") }
        append(lines: lines)
    }

    func logEvent(tag: String, level: String = "INFO", message: String) {
        let ts = ISO8601DateFormatter().string(from: Date())
        append(lines: ["[\(ts)] [\(tag.uppercased())] [\(level)] \(message)"])
    }

    func logError(tag: String, error: Error) {
        let nsError = error as NSError
        var parts: [String] = [nsError.localizedDescription]
        if let reason = nsError.userInfo[NSLocalizedFailureReasonErrorKey] as? String, !reason.isEmpty {
            parts.append(reason)
        }
        if let underlying = nsError.userInfo[NSUnderlyingErrorKey] as? NSError {
            parts.append(underlying.localizedDescription)
        }
        let message = parts.joined(separator: " | ")
        logEvent(tag: tag, level: "ERROR", message: message)
    }

    func logSyncDetail(direction: SyncDirection, action: String, taskId: String?, storyId: String?, metadata: [String: Any] = [:], dryRun: Bool = false) {
        var payload: [String: Any] = [
            "direction": direction.rawValue,
            "action": action
        ]
        if let taskId { payload["taskId"] = taskId }
        if let storyId { payload["storyId"] = storyId }
        if !metadata.isEmpty { payload["metadata"] = metadata }
        if dryRun { payload["dryRun"] = true }

        if let data = try? JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys]),
           let json = String(data: data, encoding: .utf8) {
            let ts = ISO8601DateFormatter().string(from: Date())
            append(lines: ["[\(ts)] [DETAIL] \(json)"])
        } else {
            logEvent(tag: "sync", level: "ERROR", message: "Unable to encode sync detail: \(payload)")
        }
    }

    #if canImport(AppKit)
    func revealLogInFinder() {
        guard let url = logFileURL() else { return }
        NSWorkspace.shared.activateFileViewerSelecting([url])
        NSApp.activate(ignoringOtherApps: true)
    }

    func openLogsFolder() {
        guard let lib = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first else { return }
        let logsDir = lib.appendingPathComponent("Logs").appendingPathComponent("RemindersMenuBar", isDirectory: true)
        NSWorkspace.shared.open(logsDir)
        NSApp.activate(ignoringOtherApps: true)
    }
    #endif
}
