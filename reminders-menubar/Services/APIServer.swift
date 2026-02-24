//
//  APIServer.swift
//  reminders-menubar
//
//  Complete API Server using Swifter
//
//  To use this:
//  1. Add Swifter via Swift Package Manager
//  2. Add Swifter to the "reminders-menubar" target
//

import Foundation
import Swifter
import EventKit
import Combine

@MainActor
class APIServer {
    static let shared = APIServer()

    private let server = HttpServer()
    private(set) var port: in_port_t = 7777
    private var isRunning = false
    private var cancellables = Set<AnyCancellable>()

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
        setupRoutes()

        // Observe preference changes (@MainActor ensures we're on main thread)
        UserPreferences.shared.$apiServerEnabled
            .sink { [weak self] enabled in
                print("🔔 API Server enabled changed to: \(enabled)")
                self?.handleServerEnabledChange(enabled)
            }
            .store(in: &cancellables)

        UserPreferences.shared.$apiServerPort
            .sink { [weak self] newPort in
                print("🔔 API Server port changed to: \(newPort)")
                self?.handlePortChange(newPort)
            }
            .store(in: &cancellables)
    }

    // 必须在初始化完成后调用此方法启动服务
    func initialize() {
        let enabled = UserPreferences.shared.apiServerEnabled
        print("🔧 APIServer.initialize() called, apiServerEnabled: \(enabled)")
        if enabled {
            try? start(port: in_port_t(UserPreferences.shared.apiServerPort))
        }
    }

    // MARK: - Server Lifecycle

    func startIfEnabled() {
        if UserPreferences.shared.apiServerEnabled && !isRunning {
            try? start(port: in_port_t(UserPreferences.shared.apiServerPort))
        }
    }

    func start(port: in_port_t = 7777) throws {
        self.port = port
        guard !isRunning else {
            if self.port == port {
                print("API Server already running on port \(self.port)")
            } else {
                print("API Server already running on port \(self.port), restarting on \(port)")
                stop()
                try start(port: port)
            }
            return
        }

        try server.start(port)
        isRunning = true
        print("🚀 API Server started on port \(port)")
        print("📡 http://localhost:\(port)")
    }

    func stop() {
        server.stop()
        isRunning = false
        print("🛑 API Server stopped")
    }

    func restart() throws {
        let currentPort = port
        stop()
        Thread.sleep(forTimeInterval: 0.5)
        try start(port: currentPort)
    }

    private func handleServerEnabledChange(_ enabled: Bool) {
        print("🔄 handleServerEnabledChange: \(enabled)")
        if enabled {
            do {
                try start(port: in_port_t(UserPreferences.shared.apiServerPort))
            } catch {
                print("❌ Failed to start API server: \(error)")
            }
        } else {
            stop()
        }
    }

    private func handlePortChange(_ newPort: Int) {
        guard UserPreferences.shared.apiServerEnabled else { return }

        if isRunning && in_port_t(newPort) != port {
            print("🔄 Port changed from \(port) to \(newPort), restarting server...")
            try? restart()
        }
    }

    // MARK: - Routes Setup

    private func setupRoutes() {
        // CORS middleware
        server.middleware.append { [weak self] request in
            if request.method == "OPTIONS" {
                let headers: [String: String] = [
                    "Access-Control-Allow-Origin": "*",
                    "Access-Control-Allow-Methods": "GET, POST, PATCH, DELETE, OPTIONS",
                    "Access-Control-Allow-Headers": "Content-Type"
                ]
                return .raw(200, "OK", headers) { _ in }
            }
            return nil
        }

        // Status endpoint
        server.GET["/api/v1/status"] = { [weak self] _ in
            guard let self = self else { return .internalServerError }

            let status = RemindersService.shared.authorizationStatus()
            let statusString: String
            switch status {
            case .authorized, .fullAccess: statusString = "authorized"
            case .writeOnly: statusString = "writeOnly"
            case .denied: statusString = "denied"
            case .notDetermined: statusString = "notDetermined"
            case .restricted: statusString = "restricted"
            @unknown default: statusString = "unknown"
            }

            return .ok(.json([
                "status": statusString,
                "serverPort": Int(self.port),
                "serverEnabled": UserPreferences.shared.apiServerEnabled
            ]))
        }

        // Projects endpoints (Todoist-compatible)
        server.GET["/api/v1/projects"] = { [weak self] _ in
            guard let self = self else { return .internalServerError }
            let calendars = RemindersService.shared.getCalendars()
            let responses = calendars.map { self.todoistProjectDictionary(from: $0) }
            return .ok(.json(responses))
        }

        // Tasks endpoints (Todoist-compatible)
        server.GET["/api/v1/tasks"] = { [weak self] request in
            guard let self = self else { return .internalServerError }

            let filterParam = request.queryParams.first { $0.0 == "filter" }?.1
            let projectParam = request.queryParams.first { $0.0 == "project_id" }?.1
                ?? request.queryParams.first { $0.0 == "project_ids" }?.1
                ?? request.queryParams.first { $0.0 == "projects" }?.1
            let excludeProjectParam = request.queryParams.first { $0.0 == "exclude_project_ids" }?.1
                ?? request.queryParams.first { $0.0 == "exclude_projects" }?.1
            let projectNameParam = request.queryParams.first { $0.0 == "project_name" }?.1
                ?? request.queryParams.first { $0.0 == "project_names" }?.1
            let excludeProjectNameParam = request.queryParams.first { $0.0 == "exclude_project_names" }?.1
                ?? request.queryParams.first { $0.0 == "exclude_project_name" }?.1

            let includeProjectIds = self.parseCommaSeparatedIds(projectParam)
            let excludeProjectIds = self.parseCommaSeparatedIds(excludeProjectParam)
            let includeProjectNames = self.parseCommaSeparatedNames(projectNameParam)
            let excludeProjectNames = self.parseCommaSeparatedNames(excludeProjectNameParam)

            let allCalendars = RemindersService.shared.getCalendars()
            var calendars: [EKCalendar]
            let includeNameIds = self.projectIdsMatchingNames(includeProjectNames, calendars: allCalendars)
            let excludeNameIds = self.projectIdsMatchingNames(excludeProjectNames, calendars: allCalendars)
            let resolvedIncludeIds = includeProjectIds + includeNameIds
            let resolvedExcludeIds = excludeProjectIds + excludeNameIds

            if !resolvedIncludeIds.isEmpty || !includeProjectNames.isEmpty {
                var byId: [String: EKCalendar] = [:]
                resolvedIncludeIds.forEach {
                    if let calendar = RemindersService.shared.getCalendar(withIdentifier: $0) {
                        byId[calendar.calendarIdentifier] = calendar
                    }
                }
                calendars = Array(byId.values)
            } else {
                calendars = allCalendars
            }
            if !resolvedExcludeIds.isEmpty {
                calendars = calendars.filter { !resolvedExcludeIds.contains($0.calendarIdentifier) }
            }

            var reminders = RemindersService.shared.fetchReminders(in: calendars)

            if let filter = filterParam {
                reminders = self.filterReminders(reminders, filter: filter)
            } else {
                reminders = reminders.filter { !$0.isCompleted }
            }

            reminders = self.sortRemindersByDueDate(reminders)

            let responses = reminders.map { self.todoistTaskDictionary(from: $0) }
            return .ok(.json(responses))
        }

        // Create task (Todoist-compatible)
        server.POST["/api/v1/tasks"] = { [weak self] request in
            guard let self = self else { return .internalServerError }

            switch self.parseCreateTaskParams(from: request) {
            case .failure(let response):
                return response
            case .success(let params):
                let calendar: EKCalendar
                if let projectId = params.projectId,
                   let c = RemindersService.shared.getCalendar(withIdentifier: projectId) {
                    calendar = c
                } else if let defaultCalendar = RemindersService.shared.getDefaultCalendar() {
                    calendar = defaultCalendar
                } else {
                    return HttpResponse.badRequest(["error": "No calendar available"])
                }

                let newReminder = RemindersService.shared.createReminder(in: calendar)
                newReminder.title = params.content
                newReminder.notes = params.description
                newReminder.ekPriority = self.reminderPriority(from: params.priority)

                self.applyDueDate(from: params, to: newReminder)

                RemindersService.shared.save(reminder: newReminder)

                let response = self.todoistTaskDictionary(from: newReminder)
                return .raw(200, "OK", ["Content-Type": "application/json"]) { writer in
                    guard let jsonData = try? JSONSerialization.data(withJSONObject: response) else { return }
                    try? writer.write(jsonData)
                }
            }
        }

        // Close task (Todoist-compatible)
        server.POST["/api/v1/tasks/:id/close"] = { [weak self] request in
            guard let self = self else { return .internalServerError }
            guard let id = request.params[":id"] else {
                return HttpResponse.badRequest(["error": "Missing ID"])
            }

            guard let reminder = RemindersService.shared.fetchReminder(withIdentifier: id) else {
                return HttpResponse.notFound(["error": "Reminder not found"])
            }

            reminder.isCompleted = true
            reminder.completionDate = Date()
            RemindersService.shared.save(reminder: reminder)

            return self.todoistNullResponse()
        }

        // Reopen task (Todoist-compatible)
        server.POST["/api/v1/tasks/:id/reopen"] = { [weak self] request in
            guard let self = self else { return .internalServerError }
            guard let id = request.params[":id"] else {
                return HttpResponse.badRequest(["error": "Missing ID"])
            }

            guard let reminder = RemindersService.shared.fetchReminder(withIdentifier: id) else {
                return HttpResponse.notFound(["error": "Reminder not found"])
            }

            reminder.isCompleted = false
            reminder.completionDate = nil
            RemindersService.shared.save(reminder: reminder)

            return self.todoistNullResponse()
        }

        // Delete task (Todoist-compatible)
        server.DELETE["/api/v1/tasks/:id"] = { [weak self] request in
            guard let self = self else { return .internalServerError }
            guard let id = request.params[":id"] else {
                return HttpResponse.badRequest(["error": "Missing ID"])
            }

            guard let reminder = RemindersService.shared.fetchReminder(withIdentifier: id) else {
                return HttpResponse.notFound(["error": "Reminder not found"])
            }

            RemindersService.shared.remove(reminder: reminder)
            return self.todoistNullResponse()
        }

        // Health check
        server.GET["/health"] = { [weak self] _ in
            guard let self = self else { return .internalServerError }
            return .ok(.json([
                "status": "ok",
                "serverPort": Int(self.port),
                "serverEnabled": UserPreferences.shared.apiServerEnabled
            ]))
        }

        // Root endpoint
        server.GET["/"] = { [weak self] _ in
            guard let self = self else { return .internalServerError }
            return .ok(.json([
                "name": "Reminders MenuBar API",
                "version": "1.0",
                "serverPort": Int(self.port),
                "endpoints": [
                    "GET /",
                    "GET /health",
                    "GET /api/v1/status",
                    "GET /api/v1/projects",
                    "GET /api/v1/tasks",
                    "POST /api/v1/tasks",
                    "POST /api/v1/tasks/:id/close",
                    "POST /api/v1/tasks/:id/reopen",
                    "DELETE /api/v1/tasks/:id"
                ]
            ]))
        }
    }

    private struct CreateTaskParams {
        let content: String
        let description: String?
        let projectId: String?
        let dueDate: String?
        let dueDatetime: String?
        let dueString: String?
        let priority: Int?
    }

    private enum TaskParseResult {
        case success(CreateTaskParams)
        case failure(HttpResponse)
    }

    private func parseCreateTaskParams(from request: HttpRequest) -> TaskParseResult {
        guard !request.body.isEmpty else {
            return .failure(HttpResponse.badRequest(["error": "Missing body"]))
        }

        guard let jsonObject = try? JSONSerialization.jsonObject(with: Data(request.body)),
              let payload = jsonObject as? [String: Any] else {
            return .failure(HttpResponse.badRequest(["error": "Invalid JSON"]))
        }

        let rawContent = (payload["content"] as? String) ?? (payload["title"] as? String)
        let content = rawContent?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !content.isEmpty else {
            return .failure(HttpResponse.badRequest(["error": "Missing content"]))
        }

        let description = (payload["description"] as? String) ?? (payload["notes"] as? String)
        let projectId = stringValue(payload["project_id"])
            ?? (payload["listId"] as? String)
            ?? (payload["list_id"] as? String)
        let priority = payload["priority"] as? Int

        var dueDate = (payload["due_date"] as? String) ?? (payload["dueDate"] as? String)
        var dueDatetime = (payload["due_datetime"] as? String) ?? (payload["dueDatetime"] as? String)
        var dueString = (payload["due_string"] as? String) ?? (payload["dueString"] as? String)

        if let due = payload["due"] as? [String: Any] {
            if dueDate == nil { dueDate = due["date"] as? String }
            if dueDatetime == nil { dueDatetime = due["datetime"] as? String }
            if dueString == nil { dueString = due["string"] as? String }
        }

        return .success(CreateTaskParams(
            content: content,
            description: description,
            projectId: projectId,
            dueDate: dueDate,
            dueDatetime: dueDatetime,
            dueString: dueString,
            priority: priority
        ))
    }

    private func applyDueDate(from params: CreateTaskParams, to reminder: EKReminder) {
        if let dueDatetime = params.dueDatetime,
           let date = parseISODate(dueDatetime) {
            reminder.dueDateComponents = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: date
            )
            return
        }

        if let dueDate = params.dueDate,
           let date = parseDateOnly(dueDate) {
            reminder.dueDateComponents = Calendar.current.dateComponents(
                [.year, .month, .day],
                from: date
            )
            return
        }

        if let dueString = params.dueString,
           let parsed = DateParser.shared.getDate(from: dueString) {
            if parsed.hasTime {
                reminder.dueDateComponents = Calendar.current.dateComponents(
                    [.year, .month, .day, .hour, .minute],
                    from: parsed.date
                )
            } else {
                reminder.dueDateComponents = Calendar.current.dateComponents(
                    [.year, .month, .day],
                    from: parsed.date
                )
            }
        }
    }

    private func parseISODate(_ value: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: value) {
            return date
        }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: value)
    }

    private func parseCommaSeparatedIds(_ raw: String?) -> [String] {
        guard let raw else { return [] }
        return splitQueryList(normalizeQueryValue(raw))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func parseCommaSeparatedNames(_ raw: String?) -> [String] {
        guard let raw else { return [] }
        return splitQueryList(normalizeQueryValue(raw))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty }
    }

    private func projectIdsMatchingNames(_ names: [String], calendars: [EKCalendar]) -> [String] {
        guard !names.isEmpty else { return [] }
        let nameSet = Set(names.map { $0.lowercased() })
        return calendars
            .filter { nameSet.contains($0.title.lowercased()) }
            .map { $0.calendarIdentifier }
    }

    private func normalizeQueryValue(_ raw: String) -> String {
        let plusReplaced = raw.replacingOccurrences(of: "+", with: " ")
        return plusReplaced.removingPercentEncoding ?? plusReplaced
    }

    private func splitQueryList(_ value: String) -> [String] {
        let separators = CharacterSet(charactersIn: ",，;、")
        return value.components(separatedBy: separators)
    }

    private func parseDateOnly(_ value: String) -> Date? {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: value)
    }

    private func stringValue(_ value: Any?) -> String? {
        switch value {
        case let string as String:
            return string
        case let number as NSNumber:
            return number.stringValue
        default:
            return nil
        }
    }

    private func reminderPriority(from todoistPriority: Int?) -> EKReminderPriority {
        switch todoistPriority {
        case 1:
            return .high
        case 2:
            return .medium
        case 3:
            return .low
        default:
            return .none
        }
    }

    private func todoistPriority(from reminder: EKReminder) -> Int {
        switch reminder.ekPriority {
        case .high:
            return 1
        case .medium:
            return 2
        case .low:
            return 3
        default:
            return 4
        }
    }

    private func todoistProjectDictionary(from calendar: EKCalendar) -> [String: Any] {
        var dict: [String: Any] = [
            "id": calendar.calendarIdentifier,
            "name": calendar.title
        ]
        if let color = calendar.cgColor?.hexString {
            dict["color"] = color
        }
        return dict
    }

    private func todoistTaskDictionary(from reminder: EKReminder) -> [String: Any] {
        var dict: [String: Any] = [
            "id": reminder.calendarItemIdentifier,
            "content": reminder.title ?? "",
            "checked": reminder.isCompleted,
            "priority": todoistPriority(from: reminder)
        ]
        if let notes = reminder.notes {
            dict["description"] = notes
        }
        if let projectId = reminder.calendar?.calendarIdentifier {
            dict["project_id"] = projectId
        }
        if let due = todoistDueDictionary(from: reminder) {
            dict["due"] = due
        }
        if let createdAt = reminder.creationDate {
            dict["created_at"] = ISO8601DateFormatter().string(from: createdAt)
        }
        if let completedAt = reminder.completionDate {
            dict["completed_at"] = ISO8601DateFormatter().string(from: completedAt)
        }
        return dict
    }

    private func todoistDueDictionary(from reminder: EKReminder) -> [String: Any]? {
        guard let components = reminder.dueDateComponents,
              let date = components.date else {
            return nil
        }

        let dateOnlyFormatter = DateFormatter()
        dateOnlyFormatter.calendar = Calendar(identifier: .iso8601)
        dateOnlyFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateOnlyFormatter.timeZone = TimeZone.current
        dateOnlyFormatter.dateFormat = "yyyy-MM-dd"

        if components.hour != nil || components.minute != nil {
            return [
                "datetime": ISO8601DateFormatter().string(from: date),
                "timezone": TimeZone.current.identifier
            ]
        }

        return ["date": dateOnlyFormatter.string(from: date)]
    }

    private func todoistNullResponse() -> HttpResponse {
        return .raw(200, "OK", ["Content-Type": "application/json"]) { writer in
            try? writer.write(Data("null".utf8))
        }
    }

    private func sortRemindersByDueDate(_ reminders: [EKReminder]) -> [EKReminder] {
        return reminders.sorted { lhs, rhs in
            let lhsDate = lhs.dueDateComponents?.date
            let rhsDate = rhs.dueDateComponents?.date

            switch (lhsDate, rhsDate) {
            case let (l?, r?):
                if l != r { return l < r }
            case (_?, nil):
                return true
            case (nil, _?):
                return false
            case (nil, nil):
                if let lCreated = lhs.creationDate, let rCreated = rhs.creationDate, lCreated != rCreated {
                    return lCreated > rCreated
                }
                break
            }

            if let lCreated = lhs.creationDate, let rCreated = rhs.creationDate, lCreated != rCreated {
                return lCreated < rCreated
            }
            return (lhs.title ?? "") < (rhs.title ?? "")
        }
    }

    private func filterReminders(_ reminders: [EKReminder], filter: String) -> [EKReminder] {
        let calendar = Calendar.current

        switch filter {
        case "today":
            return reminders.filter { reminder in
                guard let dueDate = reminder.dueDateComponents?.date else { return false }
                return calendar.isDateInToday(dueDate)
            }
        case "tomorrow":
            return reminders.filter { reminder in
                guard let dueDate = reminder.dueDateComponents?.date else { return false }
                return calendar.isDateInTomorrow(dueDate)
            }
        case "completed":
            return reminders.filter { $0.isCompleted }
        case "all":
            return reminders
        default:
            return reminders
        }
    }
}

// MARK: - Helper extensions for Swifter

extension HttpResponse {
    static func json<T: Encodable>(_ value: T) -> HttpResponse {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(value) else {
            return .internalServerError
        }
        return .raw(200, "OK", ["Content-Type": "application/json"], { try? $0.write(data) })
    }

    static func created<T: Encodable>(_ value: T) -> HttpResponse {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(value) else {
            return .internalServerError
        }
        return .raw(201, "Created", ["Content-Type": "application/json"], { try? $0.write(data) })
    }

    static func notFound<T: Encodable>(_ value: T) -> HttpResponse {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(value) else {
            return .notFound
        }
        return .raw(404, "Not Found", ["Content-Type": "application/json"], { try? $0.write(data) })
    }

    static func badRequest<T: Encodable>(_ value: T) -> HttpResponse {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(value) else {
            return .badRequest(nil)
        }
        return .raw(400, "Bad Request", ["Content-Type": "application/json"], { try? $0.write(data) })
    }
}
