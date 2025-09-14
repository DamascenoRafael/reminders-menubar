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
            if pr.tasks.isEmpty { return }

            var mappingUpdates: [PullRequest.Update] = []
            let calendars = RemindersService.shared.getCalendars()
            let defaultCalendar = RemindersService.shared.getDefaultCalendar() ?? calendars.first

            for t in pr.tasks {
                // Create EKReminder
                let ek = EKReminder(eventStore: RemindersService.shared.eventStore)
                ek.title = t.title
                if let due = t.dueDate {
                    let date = Date(timeIntervalSince1970: due / 1000.0)
                    ek.dueDateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
                }
                if let cal = defaultCalendar { ek.calendar = cal }

                // Add a friendly marker in notes for the user (optional)
                if let ref = t.ref {
                    let createdLine: String = {
                        if let created = t.createdAt { 
                            let d = Date(timeIntervalSince1970: created / 1000.0)
                            let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd HH:mm"
                            return "[Created: \(f.string(from: d))]"
                        }
                        return ""
                    }()
                    let dueLine: String = {
                        if let due = t.dueDate { 
                            let d = Date(timeIntervalSince1970: due / 1000.0)
                            let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
                            return "(due: \(f.string(from: d)))"
                        }
                        return ""
                    }()
                    let meta = [
                        "BOB: \(ref)",
                        t.storyId != nil ? "| Story: \(t.storyId!)" : nil,
                        t.goalId != nil ? "| Goal: \(t.goalId!)" : nil
                    ].compactMap { $0 }.joined(separator: " ")
                    var lines = [meta, "[\(Self.timestampNow())] Created via Push"]
                    if !dueLine.isEmpty { lines[1] += " " + dueLine }
                    if !createdLine.isEmpty { lines.append(createdLine) }
                    ek.notes = lines.joined(separator: "\n")
                }

                RemindersService.shared.save(reminder: ek)
                // Track mapping to set reminderId on BOB task
                mappingUpdates.append(.init(id: t.id, reminderId: ek.calendarItemIdentifier, completed: nil))
            }

            // POST mapping back via pull endpoint
            await postPullUpdates(updates: mappingUpdates)
        } catch {
            // Silent fail to avoid UI disruption
        }
    }

    func reportCompletion(for reminder: EKReminder) async {
        guard isConfigured else { return }
        let update = PullRequest.Update(id: nil, reminderId: reminder.calendarItemIdentifier, completed: reminder.isCompleted)
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
        } catch {
            // Silent fail
        }
    }

    private static func timestampNow() -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd HH:mm"
        return f.string(from: Date())
    }
}

