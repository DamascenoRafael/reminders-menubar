import AppKit
import EventKit

enum ReminderCopyService {
    static func copyReminder(_ reminder: EKReminder) {
        let text = buildFormattedText(
            options: UserPreferences.shared.copyPropertyOptions,
            variables: buildVariables(from: reminder),
            includePropertyNames: UserPreferences.shared.copyIncludePropertyNames
        )

        guard !text.isEmpty else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    static func previewText(options: [CopyPropertyOption], includePropertyNames: Bool) -> String {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let sampleDate = Calendar.current.date(bySettingHour: 15, minute: 0, second: 0, of: tomorrow) ?? tomorrow

        let sampleVariables: [CopyProperty: String] = [
            .title: rmbLocalized(.copySampleTitle),
            .notes: rmbLocalized(.copySampleNotes),
            .date: sampleDate.absoluteDateDescription(withTime: true),
            .priority: priorityLabel(for: .high),
            .list: rmbLocalized(.copySampleList),
            .url: "https://example.com/recipe",
            .tags: rmbLocalized(.copySampleTags)
        ]

        return buildFormattedText(
            options: options,
            variables: sampleVariables,
            includePropertyNames: includePropertyNames
        )
    }

    private static func buildFormattedText(
        options: [CopyPropertyOption],
        variables: [CopyProperty: String],
        includePropertyNames: Bool
    ) -> String {
        return options
            .filter { $0.isEnabled && $0.property.isAvailable }
            .compactMap { option -> String? in
                guard let value = variables[option.property], !value.isEmpty else {
                    return nil
                }
                if includePropertyNames {
                    return "\(option.property.displayName): \(value)"
                }
                return value
            }
            .joined(separator: "\n")
    }

    private static func buildVariables(from reminder: EKReminder) -> [CopyProperty: String] {
        var variables: [CopyProperty: String] = [
            .title: reminder.title ?? "",
            .notes: reminder.notes ?? "",
            .date: reminder.dueDateComponents?.date?.absoluteDateDescription(withTime: reminder.hasTime) ?? "",
            .priority: priorityLabel(for: reminder.ekPriority),
            .list: reminder.calendar?.title ?? "",
            .url: reminder.attachedUrl?.absoluteString ?? ""
        ]
        if #available(macOS 12, *) {
            let tags = reminder.ekTags
            variables[.tags] = tags.isEmpty ? "" : tags.map { "#\($0.name)" }.joined(separator: " ")
        }
        return variables
    }

    private static func priorityLabel(for priority: EKReminderPriority) -> String {
        if priority == .none {
            return ""
        }
        return priority.title
    }
}
