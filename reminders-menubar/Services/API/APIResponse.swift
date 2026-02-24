//
//  APIResponse.swift
//  reminders-menubar
//
//  API Response Models for REST API
//

import Foundation
import EventKit

// MARK: - Codable Models

struct ReminderListResponse: Codable {
    let id: String
    let name: String
    let color: String?
    let count: Int?

    init(from calendar: EKCalendar) {
        self.id = calendar.calendarIdentifier
        self.name = calendar.title
        self.color = calendar.cgColor?.hexString
        self.count = nil
    }
}

struct ReminderResponse: Codable {
    let id: String
    let title: String
    let isCompleted: Bool
    let dueDate: String?
    let notes: String?
    let listId: String?
    let listName: String?
    let priority: Int?

    init(from reminder: EKReminder) {
        self.id = reminder.calendarItemIdentifier
        self.title = reminder.title ?? ""
        self.isCompleted = reminder.isCompleted
        self.notes = reminder.notes
        self.listId = reminder.calendar?.calendarIdentifier
        self.listName = reminder.calendar?.title
        self.priority = reminder.priority > 0 ? Int(reminder.priority) : nil

        if let dueDate = reminder.dueDateComponents?.date {
            let formatter = ISO8601DateFormatter()
            self.dueDate = formatter.string(from: dueDate)
        } else {
            self.dueDate = nil
        }
    }
}

struct CreateReminderRequest: Codable {
    let title: String
    let listId: String?
    let dueDate: String?
    let notes: String?
}

struct UpdateReminderRequest: Codable {
    let title: String?
    let listId: String?
    let dueDate: String?
}

struct APIError: Codable {
    let error: String
}

struct StatusResponse: Codable {
    let status: String
    let serverPort: Int
}

// MARK: - Helpers

extension CGColor {
    var hexString: String? {
        guard let components = components, components.count >= 3 else { return nil }
        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
