// Created by Barrett Jacobsen

import AppKit
import EventKit

enum ReminderCopyService {
    static func copyReminder(_ reminder: EKReminder) {
        let template = UserPreferences.shared.copyTemplate
        let trimEnabled = UserPreferences.shared.copyTrimEnabled
        let formatted = formatReminder(reminder, template: template, trim: trimEnabled)

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(formatted, forType: .string)
    }

    static func formatReminder(_ reminder: EKReminder, template: String, trim: Bool) -> String {
        let variables = buildVariables(from: reminder)
        var result = template

        if trim {
            result = trimmedSubstitution(template: result, variables: variables)
        } else {
            for (key, value) in variables {
                result = result.replacingOccurrences(of: "{\(key)}", with: value)
            }
        }

        return result
    }

    static func previewText(template: String, trim: Bool) -> String {
        let sampleVariables: [String: String] = [
            "title": "Buy groceries",
            "notes": "From the farmers market",
            "date": "Tomorrow at 3:00 PM",
            "priority": "High",
            "list": "Shopping",
            "url": "https://example.com"
        ]

        var result = template

        if trim {
            result = trimmedSubstitution(template: result, variables: sampleVariables)
        } else {
            for (key, value) in sampleVariables {
                result = result.replacingOccurrences(of: "{\(key)}", with: value)
            }
        }

        return result
    }

    // MARK: - Private

    private static func buildVariables(from reminder: EKReminder) -> [String: String] {
        var variables: [String: String] = [:]

        variables["title"] = reminder.title ?? ""
        variables["notes"] = reminder.notes ?? ""
        variables["date"] = reminder.relativeDateDescription ?? ""
        variables["priority"] = priorityLabel(for: reminder.ekPriority)
        variables["list"] = reminder.calendar?.title ?? ""
        variables["url"] = reminder.attachedUrl?.absoluteString ?? ""

        return variables
    }

    private static func priorityLabel(for priority: EKReminderPriority) -> String {
        switch priority {
        case .high:
            return rmbLocalized(.editReminderPriorityHighOption)
        case .medium:
            return rmbLocalized(.editReminderPriorityMediumOption)
        case .low:
            return rmbLocalized(.editReminderPriorityLowOption)
        default:
            return ""
        }
    }

    private static func trimmedSubstitution(template: String, variables: [String: String]) -> String {
        let lines = template.components(separatedBy: "\\n")
        var resultLines: [String] = []

        for line in lines {
            var processedLine = line

            for (key, value) in variables {
                processedLine = processedLine.replacingOccurrences(of: "{\(key)}", with: value)
            }

            // Remove dangling separators around empty values
            // Clean up patterns like "text - " or " - text" or " | " left by empty values
            processedLine = processedLine.replacingOccurrences(
                of: "\\s*[\\-\\|:,]\\s*$",
                with: "",
                options: .regularExpression
            )
            processedLine = processedLine.replacingOccurrences(
                of: "^\\s*[\\-\\|:,]\\s*",
                with: "",
                options: .regularExpression
            )
            // Clean up double separators (e.g., "title |  | list" -> "title | list")
            processedLine = processedLine.replacingOccurrences(
                of: "\\s*[\\-\\|:,]\\s*[\\-\\|:,]\\s*",
                with: " ",
                options: .regularExpression
            )

            let trimmed = processedLine.trimmingCharacters(in: .whitespaces)
            if !trimmed.isEmpty {
                resultLines.append(processedLine)
            }
        }

        return resultLines.joined(separator: "\n")
    }
}
