import Foundation
import EventKit

@MainActor
class BobSyncService: ObservableObject {
    static let shared = BobSyncService()

    private init() {}

    private let session: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        return URLSession(configuration: config)
    }()

    private struct PushResponse: Decodable {
        struct TaskItem: Decodable {
            let id: String
            let title: String
            let dueDate: Double?
            let ref: String?
            let createdAt: Double?
            let storyId: String?
            let goalId: String?
        }
        let ok: Bool?
        let tasks: [TaskItem]
    }

    private struct PullRequest: Encodable {
        struct Update: Encodable {
            let id: String?
            let reminderId: String?
            let completed: Bool?
        }
        let uid: String
        let tasks: [Update]
    }

    var isConfigured: Bool {
        let up = UserPreferences.shared
        return !up.bobBaseUrl.trimmingCharacters(in: .whitespaces).isEmpty &&
               !up.bobUserUid.trimmingCharacters(in: .whitespaces).isEmpty &&
               !up.bobRemindersSecret.trimmingCharacters(in: .whitespaces).isEmpty
    }

    func syncFromBob() async {
        guard isConfigured else { return }
        LogService.shared.log(.info, .sync, "Sync (CF endpoint) started")
        let up = UserPreferences.shared

        // Build request
        guard var comps = URLComponents(string: up.bobBaseUrl + "/reminders/push") else { return }
        comps.queryItems = [URLQueryItem(name: "uid", value: up.bobUserUid)]
        guard let url = comps.url else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.setValue(up.bobRemindersSecret, forHTTPHeaderField: "x-reminders-secret")

        do {
            let (data, resp) = try await session.data(for: req)
            guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else { return }
            let pr = try JSONDecoder().decode(PushResponse.self, from: data)
            if pr.tasks.isEmpty {
                LogService.shared.log(.info, .sync, "Sync: no tasks to import")
                return
            }

            var mappingUpdates: [PullRequest.Update] = []
            let calendars = RemindersService.shared.getCalendars()
            let defaultCalendar = RemindersService.shared.getDefaultCalendar() ?? calendars.first

            var createdCount = 0
            for t in pr.tasks {
                // Create EKReminder
                let ek = EKReminder(eventStore: RemindersService.shared.eventStore)
                ek.title = t.title
                if let due = t.dueDate {
                    let date = Date(timeIntervalSince1970: due / 1000.0)
                    ek.dueDateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
                }
                if let cal = defaultCalendar { ek.calendar = cal }

                // Add structured marker in notes and preserve any user notes (after separator)
                if let ref = t.ref {
                    let createdDate = t.createdAt.map { Date(timeIntervalSince1970: $0 / 1000.0) }
                    let dueDate = t.dueDate.map { Date(timeIntervalSince1970: $0 / 1000.0) }
                    let meta = NotesMeta(
                        ref: ref,
                        storyId: t.storyId,
                        goalId: t.goalId,
                        theme: nil,
                        createdAt: createdDate,
                        updatedAt: nil,
                        dueDate: dueDate,
                        lastComment: nil
                    )
                    ek.notes = NotesCodec.format(meta: meta, existing: nil)
                }

                RemindersService.shared.save(reminder: ek)
                // Track mapping to set reminderId on BOB task
                mappingUpdates.append(.init(id: t.id, reminderId: ek.calendarItemIdentifier, completed: nil))
                createdCount += 1
            }

            // POST mapping back via pull endpoint
            await postPullUpdates(updates: mappingUpdates)
            LogService.shared.log(.info, .sync, "Sync (CF endpoint) finished. Created=\(createdCount) mapped=\(mappingUpdates.count)")
        } catch {
            // Silent fail to avoid UI disruption
            LogService.shared.log(.error, .sync, "Sync (CF endpoint) error: \(error.localizedDescription)")
        }
    }

    func reportCompletion(for reminder: EKReminder) async {
        guard isConfigured else { return }
        let update = PullRequest.Update(id: nil, reminderId: reminder.calendarItemIdentifier, completed: reminder.isCompleted)
        LogService.shared.log(.info, .sync, "Report completion to BOB: id=\(reminder.calendarItemIdentifier) completed=\(reminder.isCompleted)")
        await postPullUpdates(updates: [update])
    }

    private func postPullUpdates(updates: [PullRequest.Update]) async {
        guard isConfigured, !updates.isEmpty else { return }
        let up = UserPreferences.shared
        guard let url = URL(string: up.bobBaseUrl + "/reminders/pull?uid=\(up.bobUserUid)") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue(up.bobRemindersSecret, forHTTPHeaderField: "x-reminders-secret")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = PullRequest(uid: up.bobUserUid, tasks: updates)
        do {
            req.httpBody = try JSONEncoder().encode(body)
            _ = try await session.data(for: req)
            LogService.shared.log(.debug, .network, "POST pull updates count=\(updates.count)")
        } catch {
            // Silent fail
            LogService.shared.log(.error, .network, "Failed POST pull updates: \(error.localizedDescription)")
        }
    }

    private static func timestampNow() -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd HH:mm"
        return f.string(from: Date())
    }
}
