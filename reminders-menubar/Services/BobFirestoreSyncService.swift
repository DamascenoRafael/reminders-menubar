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

        do {
            // Fetch tasks for owner; apply client-side filter akin to CF endpoint
            let snap = try await db.collection("tasks").whereField("ownerUid", isEqualTo: uid).getDocuments()
            let docs = snap.documents
            let startOfToday = Calendar.current.startOfDay(for: Date())
            let endOfToday = Calendar.current.date(byAdding: .day, value: 1, to: startOfToday)!
            let endMs = endOfToday.timeIntervalSince1970 * 1000.0

            var toAck: [(id: String, rid: String)] = []
            let defaultCalendar = RemindersService.shared.getDefaultCalendar() ?? RemindersService.shared.getCalendars().first

            for d in docs {
                let data = d.data()
                let reminderId = data["reminderId"] as? String
                let status = data["status"] as? Int ?? 0
                let dueDate = (data["dueDate"] as? NSNumber)?.doubleValue ?? (data["dueDate"] as? Double) ?? 0
                if reminderId == nil && status != 2 && (dueDate == 0 || dueDate <= endMs) {
                    let title = (data["title"] as? String) ?? ""
                    let storyId = data["storyId"] as? String
                    let goalId = data["goalId"] as? String
                    let createdAt = (data["createdAt"] as? NSNumber)?.doubleValue ?? (data["createdAt"] as? Double)

                    let ek = EKReminder(eventStore: RemindersService.shared.eventStore)
                    ek.title = title
                    if dueDate > 0 {
                        let date = Date(timeIntervalSince1970: dueDate/1000.0)
                        ek.dueDateComponents = Calendar.current.dateComponents([.year,.month,.day,.hour,.minute], from: date)
                    }
                    if let cal = defaultCalendar { ek.calendar = cal }

                    // Notes marker similar to HTTP service
                    var lines: [String] = []
                    let ref = "TK-\(String(d.documentID.prefix(6)).uppercased())"
                    var meta = ["BOB: \(ref)"]
                    if let s = storyId, !s.isEmpty { meta.append("| Story: \(s)") }
                    if let g = goalId, !g.isEmpty { meta.append("| Goal: \(g)") }
                    lines.append(meta.joined(separator: " "))
                    let tsFmt = DateFormatter(); tsFmt.dateFormat = "yyyy-MM-dd HH:mm"
                    lines.append("[\(tsFmt.string(from: Date()))] Created via Push")
                    if dueDate > 0 {
                        let dFmt = DateFormatter(); dFmt.dateFormat = "yyyy-MM-dd"
                        lines[1] += " (due: \(dFmt.string(from: Date(timeIntervalSince1970: dueDate/1000.0))))"
                    }
                    if let created = createdAt { lines.append("[Created: \(tsFmt.string(from: Date(timeIntervalSince1970: created/1000.0)))]") }
                    ek.notes = lines.joined(separator: "\n")

                    RemindersService.shared.save(reminder: ek)
                    toAck.append((id: d.documentID, rid: ek.calendarItemIdentifier))
                }
            }

            // Mark reminderId on created tasks
            for ack in toAck {
                try await db.collection("tasks").document(ack.id).setData([
                    "reminderId": ack.rid,
                    "updatedAt": FieldValue.serverTimestamp()
                ], merge: true)
            }
        } catch {
            // Silent to avoid UI disruption
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
            }
        } catch {
            // ignore
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

