import Foundation
import EventKit

#if canImport(FirebaseFirestore) && canImport(FirebaseCore)
import FirebaseFirestore

@MainActor
class BobFirestoreSyncService: ObservableObject {
    static let shared = BobFirestoreSyncService()
    private init() {}

    private var db: Firestore { Firestore.firestore() }

    func syncFromBob() async {
        FirebaseManager.shared.configureIfNeeded()
        guard let uid = FirebaseManager.shared.currentUid else { return }
        LogService.shared.log(.info, .sync, "Sync (Firestore) started for uid=\(uid)")

        do {
            // Fetch tasks for owner; apply client-side filter akin to CF endpoint
            let snap = try await db.collection("tasks").whereField("ownerUid", isEqualTo: uid).getDocuments()
            let docs = snap.documents
            let startOfToday = Calendar.current.startOfDay(for: Date())
            let endOfToday = Calendar.current.date(byAdding: .day, value: 1, to: startOfToday)!
            let endMs = endOfToday.timeIntervalSince1970 * 1000.0

            var toAck: [(id: String, rid: String)] = []
            var createdCount = 0
            let defaultCalendar = RemindersService.shared.getDefaultCalendar() ?? RemindersService.shared.getCalendars().first

            for d in docs {
                let data = d.data()
                let reminderId = data["reminderId"] as? String
                let status = data["status"] as? Int ?? 0
                let dueDate = (data["dueDate"] as? NSNumber)?.doubleValue ?? (data["dueDate"] as? Double) ?? 0
                if reminderId == nil && status != 2 && (dueDate == 0 || dueDate <= endMs) {
                    let title = (data["title"] as? String) ?? ""
                    let storyId = data["storyId"] as? String
                    var goalId = data["goalId"] as? String
                    // Timestamps can be numeric ms or Firestore Timestamp
                    let createdAtNum = (data["createdAt"] as? NSNumber)?.doubleValue ?? (data["createdAt"] as? Double)
                    let createdAtTs = data["createdAt"] as? Timestamp
                    let serverUpdatedAtNum = (data["serverUpdatedAt"] as? NSNumber)?.doubleValue ?? (data["serverUpdatedAt"] as? Double)
                    let updatedAtNum = (data["updatedAt"] as? NSNumber)?.doubleValue ?? (data["updatedAt"] as? Double)
                    let updatedAtTs = data["updatedAt"] as? Timestamp
                    let taskThemeNum = (data["theme"] as? NSNumber)?.intValue ?? (data["theme"] as? Int)
                    let taskRef = (data["ref"] as? String) ?? "TK-\(String(d.documentID.prefix(6)).uppercased())"

                    let ek = EKReminder(eventStore: RemindersService.shared.eventStore)
                    ek.title = title
                    if dueDate > 0 {
                        let date = Date(timeIntervalSince1970: dueDate/1000.0)
                        ek.dueDateComponents = Calendar.current.dateComponents([.year,.month,.day,.hour,.minute], from: date)
                    }
                    if let cal = defaultCalendar { ek.calendar = cal }

                    // Resolve theme via task -> story -> goal chain
                    var themeName: String? = nil
                    if let tTheme = taskThemeNum { themeName = Self.themeName(from: tTheme) }
                    if goalId == nil, let sId = storyId {
                        do {
                            let storySnap = try await db.collection("stories").document(sId).getDocument()
                            if let sdata = storySnap.data() {
                                if goalId == nil { goalId = sdata["goalId"] as? String }
                                if themeName == nil, let sTheme = (sdata["theme"] as? NSNumber)?.intValue ?? (sdata["theme"] as? Int) {
                                    themeName = Self.themeName(from: sTheme)
                                }
                            }
                        } catch { /* ignore */ }
                    }
                    if themeName == nil, let gId = goalId {
                        do {
                            let goalSnap = try await db.collection("goals").document(gId).getDocument()
                            if let gdata = goalSnap.data(), let gTheme = (gdata["theme"] as? NSNumber)?.intValue ?? (gdata["theme"] as? Int) {
                                themeName = Self.themeName(from: gTheme)
                            }
                        } catch { /* ignore */ }
                    }

                    // Fetch latest comment from activity_stream for this task
                    var lastComment: String? = nil
                    do {
                        let q = db.collection("activity_stream")
                            .whereField("entityId", isEqualTo: d.documentID)
                            .whereField("ownerUid", isEqualTo: uid)
                        let actSnap = try await q.getDocuments()
                        var newest: (Date, String)? = nil
                        for doc in actSnap.documents {
                            let a = doc.data()
                            guard let type = a["activityType"] as? String, type == "note_added" else { continue }
                            guard let content = a["noteContent"] as? String, !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { continue }
                            let ts = (a["timestamp"] as? Timestamp)?.dateValue() ?? Date.distantPast
                            if newest == nil || ts > newest!.0 { newest = (ts, content) }
                        }
                        lastComment = newest?.1
                    } catch { /* ignore */ }

                    // Build Notes meta (user notes preserved above separator; none at creation)
                    let createdDate: Date? = {
                        if let n = createdAtNum { return Date(timeIntervalSince1970: n/1000.0) }
                        if let t = createdAtTs { return t.dateValue() }
                        return nil
                    }()
                    let updatedDate: Date? = {
                        if let n = serverUpdatedAtNum ?? updatedAtNum { return Date(timeIntervalSince1970: n/1000.0) }
                        if let t = updatedAtTs { return t.dateValue() }
                        return nil
                    }()
                    let due = (dueDate > 0) ? Date(timeIntervalSince1970: dueDate/1000.0) : nil
                    let metaNotes = NotesMeta(ref: taskRef, storyId: storyId, goalId: goalId, theme: themeName, createdAt: createdDate, updatedAt: updatedDate, dueDate: due, lastComment: lastComment)
                    ek.notes = NotesCodec.format(meta: metaNotes, existing: nil)

                    RemindersService.shared.save(reminder: ek)
                    toAck.append((id: d.documentID, rid: ek.calendarItemIdentifier))
                    LogService.shared.log(.info, .sync, "Imported task=\(d.documentID) title=\(title)")
                    createdCount += 1
                }
            }

            // Mark reminderId on created tasks
            for ack in toAck {
                try await db.collection("tasks").document(ack.id).setData([
                    "reminderId": ack.rid,
                    "updatedAt": FieldValue.serverTimestamp()
                ], merge: true)
            }
            LogService.shared.log(.info, .sync, "Sync (Firestore) finished. Created=\(createdCount) acked=\(toAck.count)")
        } catch {
            // Silent to avoid UI disruption
            LogService.shared.log(.error, .sync, "Sync (Firestore) error: \(error.localizedDescription)")
        }
    }

    func reportCompletion(for reminder: EKReminder) async {
        FirebaseManager.shared.configureIfNeeded()
        guard let uid = FirebaseManager.shared.currentUid else { return }
        do {
            // Find task by reminderId for this owner
            let q = db.collection("tasks").whereField("ownerUid", isEqualTo: uid).whereField("reminderId", isEqualTo: reminder.calendarItemIdentifier).limit(to: 1)
            let snap = try await q.getDocuments()
            if let doc = snap.documents.first {
                try await doc.reference.setData([
                    "status": reminder.isCompleted ? 2 : 0,
                    "updatedAt": FieldValue.serverTimestamp()
                ], merge: true)
                LogService.shared.log(.info, .sync, "Reported completion to Firestore for reminderId=\(reminder.calendarItemIdentifier) completed=\(reminder.isCompleted)")
            }
        } catch {
            // ignore
            LogService.shared.log(.error, .sync, "Failed to report completion to Firestore: \(error.localizedDescription)")
        }
    }

    private static func themeName(from code: Int) -> String {
        switch code {
        case 1: return "Health"
        case 2: return "Growth"
        case 3: return "Wealth"
        case 4: return "Tribe"
        case 5: return "Home"
        default: return String(code)
        }
    }
}
#else
@MainActor
class BobFirestoreSyncService: ObservableObject {
    static let shared = BobFirestoreSyncService()
    private init() {}
    func syncFromBob() async { /* Firebase not available */ }
    func reportCompletion(for reminder: EKReminder) async { }
}
#endif
