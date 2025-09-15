import Foundation

struct NotesMeta {
    var ref: String?
    var storyId: String?
    var goalId: String?
    var theme: String?
    var createdAt: Date?
    var updatedAt: Date?
    var dueDate: Date?
    var lastComment: String?
}

enum NotesCodec {
    static let separator = "-----------------"

    static func format(meta: NotesMeta, existing: String?) -> String {
        // New format: user notes first, then separator, then BOB meta lines
        var top: [String] = []
        if let existing = existing, !existing.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            top.append(existing)
        }

        var metaLines: [String] = []
        if let r = meta.ref, !r.isEmpty { metaLines.append("Task: \(r)") }
        if let s = meta.storyId, !s.isEmpty { metaLines.append("Story: \(s)") }
        if let g = meta.goalId, !g.isEmpty { metaLines.append("Goal: \(g)") }
        if let th = meta.theme, !th.isEmpty { metaLines.append("Theme: \(th)") }
        let tsFmt = DateFormatter(); tsFmt.dateFormat = "yyyy-MM-dd HH:mm"
        if let c = meta.createdAt { metaLines.append("Created: \(tsFmt.string(from: c))") }
        if let u = meta.updatedAt { metaLines.append("Updated: \(tsFmt.string(from: u))") }
        if let d = meta.dueDate {
            let dFmt = DateFormatter(); dFmt.dateFormat = "yyyy-MM-dd"
            metaLines.append("Due: \(dFmt.string(from: d))")
        }
        if let lc = meta.lastComment, !lc.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            metaLines.append("Last comment: \(lc)")
        }

        if metaLines.isEmpty { return top.joined(separator: "\n") }
        if top.isEmpty { return ([separator] + metaLines).joined(separator: "\n") }
        return (top + [separator] + metaLines).joined(separator: "\n")
    }

    static func parse(_ notes: String?) -> (meta: NotesMeta, userNotes: String?) {
        var result = NotesMeta()
        guard let notes = notes, !notes.isEmpty else { return (result, nil) }

        // Prefer new format with meta below separator; otherwise fall back to old
        let comps = notes.components(separatedBy: "\n\(separator)\n")
        let userNotes: String?
        let metaBlock: String
        if comps.count >= 2 {
            userNotes = comps.first
            metaBlock = comps.dropFirst().joined(separator: "\n\(separator)\n")
        } else {
            // Old format support: meta on top
            let partsOld = notes.components(separatedBy: "\n\(separator)\n")
            metaBlock = partsOld.first ?? notes
            userNotes = partsOld.count > 1 ? partsOld.dropFirst().joined(separator: "\n\(separator)\n") : nil
        }

        for raw in metaBlock.split(separator: "\n") {
            let line = raw.trimmingCharacters(in: .whitespaces)
            if line.isEmpty { continue }
            if line.hasPrefix("Task:") { result.ref = line.replacingOccurrences(of: "Task:", with: "").trimmingCharacters(in: .whitespaces) }
            else if line.hasPrefix("Story:") { result.storyId = line.replacingOccurrences(of: "Story:", with: "").trimmingCharacters(in: .whitespaces) }
            else if line.hasPrefix("Goal:") { result.goalId = line.replacingOccurrences(of: "Goal:", with: "").trimmingCharacters(in: .whitespaces) }
            else if line.hasPrefix("Theme:") { result.theme = line.replacingOccurrences(of: "Theme:", with: "").trimmingCharacters(in: .whitespaces) }
            else if line.hasPrefix("Created:") {
                let v = line.replacingOccurrences(of: "Created:", with: "").trimmingCharacters(in: .whitespaces)
                let tsFmt = DateFormatter(); tsFmt.dateFormat = "yyyy-MM-dd HH:mm"; result.createdAt = tsFmt.date(from: v)
            }
            else if line.hasPrefix("Updated:") {
                let v = line.replacingOccurrences(of: "Updated:", with: "").trimmingCharacters(in: .whitespaces)
                let tsFmt = DateFormatter(); tsFmt.dateFormat = "yyyy-MM-dd HH:mm"; result.updatedAt = tsFmt.date(from: v)
            }
            else if line.hasPrefix("Due:") {
                let v = line.replacingOccurrences(of: "Due:", with: "").trimmingCharacters(in: .whitespaces)
                let dFmt = DateFormatter(); dFmt.dateFormat = "yyyy-MM-dd"; result.dueDate = dFmt.date(from: v)
            }
            else if line.hasPrefix("Last comment:") {
                result.lastComment = line.replacingOccurrences(of: "Last comment:", with: "").trimmingCharacters(in: .whitespaces)
            }
            // Back-compat compact header
            else if line.hasPrefix("BOB:") {
                let tail = line.dropFirst("BOB:".count)
                let pieces = tail.split(separator: "|")
                if let refPart = pieces.first { result.ref = String(refPart).trimmingCharacters(in: .whitespaces) }
                for p in pieces.dropFirst() {
                    let t = p.trimmingCharacters(in: .whitespaces)
                    if t.hasPrefix("Story:") { result.storyId = t.replacingOccurrences(of: "Story:", with: "").trimmingCharacters(in: .whitespaces) }
                    if t.hasPrefix("Goal:") { result.goalId = t.replacingOccurrences(of: "Goal:", with: "").trimmingCharacters(in: .whitespaces) }
                }
            }
        }

        return (result, userNotes)
    }
}
