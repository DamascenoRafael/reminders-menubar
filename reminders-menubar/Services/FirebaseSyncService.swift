import Foundation
import EventKit

#if canImport(FirebaseFirestore) && canImport(FirebaseAuth)
import FirebaseFirestore
import FirebaseAuth

struct FbTask {
    let id: String
    let title: String
    let dueDate: Double?
    let reminderId: String?
    let status: Any?
    let storyId: String?
    let goalId: String?
}

final class FirebaseSyncService {
    static let shared = FirebaseSyncService()
    private init() {}

    private func toTask(_ doc: DocumentSnapshot) -> FbTask? {
        let data = doc.data() ?? [:]
        return FbTask(
            id: doc.documentID,
            title: data["title"] as? String ?? "Task",
            dueDate: (data["dueDate"] as? NSNumber)?.doubleValue ?? data["dueDate"] as? Double,
            reminderId: data["reminderId"] as? String,
            status: data["status"],
            storyId: data["storyId"] as? String,
            goalId: data["goalId"] as? String
        )
    }

    func resolveThemeName(goalId: String?, storyId: String?, db: Firestore) async -> String? {
        // Try goal first
        if let gid = goalId {
            do {
                let snap = try await db.collection("goals").document(gid).getDocument()
                if let d = snap.data(), let t = (d["themeId"] as? String) ?? (d["theme"] as? String) { return t }
            } catch { }
        }
        if let sid = storyId {
            do {
                let snap = try await db.collection("stories").document(sid).getDocument()
                if let d = snap.data() {
                    if let t = (d["themeId"] as? String) ?? (d["theme"] as? String) { return t }
                    if let gid = d["goalId"] as? String {
                        let g = try await db.collection("goals").document(gid).getDocument()
                        if let gd = g.data(), let t = (gd["themeId"] as? String) ?? (gd["theme"] as? String) { return t }
                    }
                }
            } catch { }
        }
        return nil
    }

    func resolveSprintName(storyId: String?, db: Firestore) async -> String? {
        guard let sid = storyId else { return nil }
        do {
            let snap = try await db.collection("stories").document(sid).getDocument()
            if let d = snap.data(), let spid = d["sprintId"] as? String {
                let sp = try await db.collection("sprints").document(spid).getDocument()
                if let sd = sp.data() { return (sd["name"] as? String) ?? spid }
            }
        } catch { }
        return nil
    }

    // Creates reminders for tasks without reminderId and updates mapping/completions in Firestore
    func syncNow(targetCalendar preferredCalendar: EKCalendar?) async -> (created: Int, updated: Int, errors: [String]) {
        guard let user = Auth.auth().currentUser, let db = FirebaseManager.shared.db else {
            return (0, 0, ["Not authenticated or Firebase not configured"])
        }
        var created = 0
        var updated = 0
        var errors: [String] = []
        var createdLinkedStories = 0
        var createdWithTheme = 0

        do {
            // Load candidate tasks
            let qs = try await db.collection("tasks").whereField("ownerUid", isEqualTo: user.uid).getDocuments()
            let tasks = qs.documents.compactMap(toTask)
            let toCreate = tasks.filter { $0.reminderId == nil && !isDone($0.status) }

            // Index existing reminders by taskId to avoid duplicates
            let storeIndex = EKEventStore()
            let calendarsIndex: [EKCalendar] = await MainActor.run { RemindersService.shared.getCalendars() }
            let predicateIndex = storeIndex.predicateForReminders(in: calendarsIndex)
            let existingReminders: [EKReminder] = await withCheckedContinuation { cont in
                storeIndex.fetchReminders(matching: predicateIndex) { cont.resume(returning: $0 ?? []) }
            }
            var existingTaskIds: Set<String> = []
            existingReminders.forEach { r in
                if let first = r.notes?.split(separator: "\n").first, first.hasPrefix("BOB:") {
                    let tokens = first.replacingOccurrences(of: "BOB:", with: "").split(separator: " ")
                    for t in tokens {
                        let p = t.split(separator: "=")
                        if p.count == 2 && p[0] == "taskId" {
                            existingTaskIds.insert(String(p[1]))
                        }
                    }
                }
            }

            for t in toCreate {
                let themeName = await resolveThemeName(goalId: t.goalId, storyId: t.storyId, db: db)
                let sprintName = await resolveSprintName(storyId: t.storyId, db: db)
                let cal: EKCalendar? = await MainActor.run {
                    if let name = themeName { return RemindersService.shared.ensureCalendar(named: name) }
                    return preferredCalendar ?? RemindersService.shared.getDefaultCalendar()
                }
                guard let cal = cal else { continue }

                // Skip if a reminder with this taskId already exists
                if existingTaskIds.contains(t.id) {
                    continue
                }

                var rmb = RmbReminder()
                rmb.title = t.title
                if let due = t.dueDate { rmb.hasDueDate = true; rmb.hasTime = false; rmb.date = Date(timeIntervalSince1970: due/1000.0) }
                rmb.calendar = cal

                // Build notes: header + sprint tag line
                var lines: [String] = []
                let ts = ISO8601DateFormatter().string(from: Date())
                var headerParts: [String] = ["taskId=\(t.id)"]
                if let sid = t.storyId { headerParts.append("storyId=\(sid)") }
                if let gid = t.goalId { headerParts.append("goalId=\(gid)") }
                headerParts.append("synced=\(ts)")
                lines.append("BOB: " + headerParts.joined(separator: " "))
                if let sprintName { lines.append("#sprint: \(sprintName)") }
                if let themeName { lines.append("#theme: \(themeName)") }
                rmb.notes = lines.joined(separator: "\n")

                let rmbToSave = rmb
                await MainActor.run {
                    RemindersService.shared.createNew(with: rmbToSave, in: cal)
                }
                created += 1
                if t.storyId != nil { createdLinkedStories += 1 }
                if themeName != nil { createdWithTheme += 1 }
            }

            // Refresh and push mapping + completions back to Firestore
            let store = EKEventStore()
            let calendars: [EKCalendar] = await MainActor.run { RemindersService.shared.getCalendars() }
            let predicate = store.predicateForReminders(in: calendars)
            let all: [EKReminder] = await withCheckedContinuation { cont in
                store.fetchReminders(matching: predicate) { cont.resume(returning: $0 ?? []) }
            }
            for r in all {
                guard let first = r.notes?.split(separator: "\n").first, first.hasPrefix("BOB:") else { continue }
                // parse taskId
                let tokens = first.replacingOccurrences(of: "BOB:", with: "").split(separator: " ")
                var taskId: String? = nil
                for t in tokens {
                    let p = t.split(separator: "=")
                    if p.count == 2 && p[0] == "taskId" { taskId = String(p[1]) }
                }
                guard let tid = taskId else { continue }
                let rid = r.calendarItemIdentifier
                let ref = db.collection("tasks").document(tid)
                // Merge reminderId and status if completed
                var data: [String: Any] = ["updatedAt": FieldValue.serverTimestamp(), "reminderId": rid]
                if r.isCompleted { data["status"] = 2 }
                do { try await ref.setData(data, merge: true); updated += 1 } catch { errors.append("Update task failed: \(error.localizedDescription)") }
            }

        } catch {
            errors.append("Firestore query failed: \(error.localizedDescription)")
        }

        // Persist summary
        let summary = "created=\(created) updated=\(updated) stories=\(createdLinkedStories) themes=\(createdWithTheme)"
        DispatchQueue.main.async {
            UserPreferences.shared.lastSyncSummary = summary
        }
        SyncLogService.shared.logSync(userId: user.uid, created: created, updated: updated, linkedStories: createdLinkedStories, themed: createdWithTheme, errors: errors)

        return (created, updated, errors)
    }

    private func isDone(_ status: Any?) -> Bool {
        if let n = status as? NSNumber { return n.intValue == 2 }
        if let s = status as? String { return s.lowercased() == "done" || s == "2" }
        return false
    }
}

#else

final class FirebaseSyncService {
    static let shared = FirebaseSyncService()
    private init() {}
    func syncNow(targetCalendar: EKCalendar?) async -> (created: Int, updated: Int, errors: [String]) {
        return (0, 0, ["Firebase SDK not available"])
    }
}

#endif
