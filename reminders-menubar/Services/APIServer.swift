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

        // Observe preference changes
        UserPreferences.shared.$apiServerEnabled
            .sink { [weak self] enabled in
                self?.handleServerEnabledChange(enabled)
            }
            .store(in: &cancellables)

        UserPreferences.shared.$apiServerPort
            .sink { [weak self] newPort in
                self?.handlePortChange(newPort)
            }
            .store(in: &cancellables)

        // Auto-start if enabled
        if UserPreferences.shared.apiServerEnabled {
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
        if enabled {
            try? start(port: in_port_t(UserPreferences.shared.apiServerPort))
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
        server.middleware.append { request in
            var headers: [String: String] = [:]
            headers["Access-Control-Allow-Origin"] = "*"
            headers["Access-Control-Allow-Methods"] = "GET, POST, PATCH, DELETE, OPTIONS"
            headers["Access-Control-Allow-Headers"] = "Content-Type"

            if request.method == "OPTIONS" {
                return .ok(.headers(headers))
            }
            return nil
        }

        // Status endpoint
        server.GET["/api/v1/status"] { [weak self] _ in
            guard let self = self else { return .internalServerError }

            let status = RemindersService.shared.authorizationStatus()
            let statusString: String
            switch status {
            case .authorized: statusString = "authorized"
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

        // Lists endpoints
        server.GET["/api/v1/lists"] { _ in
            let calendars = RemindersService.shared.getCalendars()
            let responses = calendars.map(ReminderListResponse.init)
            return .ok(.json(responses))
        }

        // Reminders endpoints
        server.GET["/api/v1/reminders"] { request in
            let filterParam = request.queryParams.first { $0.0 == "filter" }?.1
            let listParam = request.queryParams.first { $0.0 == "list" }?.1

            let calendars: [EKCalendar]
            if let listId = listParam, let calendar = RemindersService.shared.getCalendar(withIdentifier: listId) {
                calendars = [calendar]
            } else {
                calendars = RemindersService.shared.getCalendars()
            }

            let predicate = EKEventStore().predicateForReminders(in: calendars)
            var reminders: [EKReminder] = []
            let semaphore = DispatchSemaphore(value: 0)

            EKEventStore().fetchReminders(matching: predicate) { fetched in
                reminders = fetched ?? []
                semaphore.signal()
            }

            _ = semaphore.wait(timeout: .now() + 5)

            // Apply filtering if needed
            if let filter = filterParam {
                reminders = self.filterReminders(reminders, filter: filter)
            }

            let responses = reminders.map(ReminderResponse.init)
            return .ok(.json(responses))
        }

        // Create reminder
        server.POST["/api/v1/reminders"] { request in
            guard let body = request.body else {
                return .badRequest(.json(["error": "Missing body"]))
            }

            do {
                let req = try JSONDecoder().decode(CreateReminderRequest.self, from: Data(body))

                let calendar: EKCalendar
                if let listId = req.listId, let c = RemindersService.shared.getCalendar(withIdentifier: listId) {
                    calendar = c
                } else if let defaultCalendar = RemindersService.shared.getDefaultCalendar() {
                    calendar = defaultCalendar
                } else {
                    return .badRequest(.json(["error": "No calendar available"]))
                }

                let newReminder = EKReminder(eventStore: EKEventStore())
                newReminder.title = req.title
                newReminder.notes = req.notes
                newReminder.calendar = calendar

                if let dueDateString = req.dueDate,
                   let dueDate = ISO8601DateFormatter().date(from: dueDateString) {
                    newReminder.dueDateComponents = Calendar.current.dateComponents(
                        [.year, .month, .day, .hour, .minute],
                        from: dueDate
                    )
                }

                RemindersService.shared.save(reminder: newReminder)

                let response = ReminderResponse(from: newReminder)
                return .created(.json(response))
            } catch {
                return .badRequest(.json(["error": error.localizedDescription]))
            }
        }

        // Complete reminder
        server.POST["/api/v1/reminders/:id/complete"] { request in
            guard let id = request.params[":id"] else {
                return .badRequest(.json(["error": "Missing ID"]))
            }

            let store = EKEventStore()
            guard let reminder = store.calendarItem(withIdentifier: id) as? EKReminder else {
                return .notFound(.json(["error": "Reminder not found"]))
            }

            reminder.isCompleted = true
            reminder.completionDate = Date()
            RemindersService.shared.save(reminder: reminder)

            let response = ReminderResponse(from: reminder)
            return .ok(.json(response))
        }

        // Delete reminder
        server.DELETE["/api/v1/reminders/:id"] { request in
            guard let id = request.params[":id"] else {
                return .badRequest(.json(["error": "Missing ID"]))
            }

            let store = EKEventStore()
            guard let reminder = store.calendarItem(withIdentifier: id) as? EKReminder else {
                return .notFound(.json(["error": "Reminder not found"]))
            }

            RemindersService.shared.remove(reminder: reminder)
            return .ok(.json(["success": true]))
        }

        // Health check
        server.GET["/health"] { [weak self] _ in
            guard let self = self else { return .internalServerError }
            return .ok(.json([
                "status": "ok",
                "serverPort": Int(self.port),
                "serverEnabled": UserPreferences.shared.apiServerEnabled
            ]))
        }

        // Root endpoint
        server.GET["/"] { [weak self] _ in
            guard let self = self else { return .internalServerError }
            return .ok(.json([
                "name": "Reminders MenuBar API",
                "version": "1.0",
                "serverPort": Int(self.port),
                "endpoints": [
                    "GET /",
                    "GET /health",
                    "GET /api/v1/status",
                    "GET /api/v1/lists",
                    "GET /api/v1/reminders",
                    "POST /api/v1/reminders",
                    "POST /api/v1/reminders/:id/complete",
                    "DELETE /api/v1/reminders/:id"
                ]
            ]))
        }
    }

    private func filterReminders(_ reminders: [EKReminder], filter: String) -> [EKReminder] {
        let now = Date()
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
            return .notFound(nil)
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
