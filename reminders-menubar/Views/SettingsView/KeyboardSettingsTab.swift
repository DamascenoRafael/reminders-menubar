import SwiftUI
import KeyboardShortcuts

struct KeyboardSettingsTab: View {
    @ObservedObject var keyboardShortcutService = KeyboardShortcutService.shared
    @ObservedObject var userPreferences = UserPreferences.shared

    private var dateShortcutExample: String {
        let exampleDate = Calendar.current.date(
            bySettingHour: 15,
            minute: 0,
            second: 0,
            of: Date()
        ) ?? Date()
        return exampleDate
            .relativeDateDescription(withTime: true)
            .replacingOccurrences(of: ", ", with: " ")
            .lowercased(with: rmbTimeFormattedLocale())
    }

    var body: some View {
        Form {
            SettingsSection {
                Toggle(
                    rmbLocalized(.keyboardShortcutEnableOpenShortcutOption, arguments: AppConstants.appName),
                    isOn: $keyboardShortcutService.isOpenRemindersMenuBarEnabled
                )

                HStack(spacing: 8) {
                    KeyboardShortcuts.Recorder(for: .openRemindersMenuBar)

                    Button(action: {
                        KeyboardShortcutService.shared.reset(.openRemindersMenuBar)
                    }) {
                        Text(rmbLocalized(.keyboardShortcutRestoreDefaultButton))
                    }
                }
                .disabled(!keyboardShortcutService.isOpenRemindersMenuBarEnabled)
            }

            SettingsDivider()

            SettingsSection(rmbLocalized(.keyboardTypingShortcutsSettingsLabel)) {
                Text(rmbLocalized(.keyboardTypingShortcutsNote))

                TypingShortcutRow(
                    shortcuts: [dateShortcutExample],
                    description: rmbLocalized(.keyboardTypingShortcutsDateDescription),
                    highlightColor: .rmbColor(.dateHighlight)
                )
                TypingShortcutRow(
                    shortcuts: ["@work", "/personal"],
                    description: rmbLocalized(.keyboardTypingShortcutsListDescription)
                )
                TypingShortcutRow(
                    shortcuts: ["!", "!!", "!!!"],
                    description: rmbLocalized(.keyboardTypingShortcutsPriorityDescription),
                    highlightColor: .rmbColor(.priorityHighlight)
                )
                TypingShortcutRow(
                    shortcuts: ["!f"],
                    description: rmbLocalized(.keyboardTypingShortcutsFlagDescription),
                    highlightColor: .rmbColor(.flaggedHighlight)
                )
                if #available(macOS 26, *) {
                    TypingShortcutRow(
                        shortcuts: ["!u"],
                        description: rmbLocalized(.keyboardTypingShortcutsUrgentDescription),
                        highlightColor: .rmbColor(.urgentHighlight)
                    )
                }
                TypingShortcutRow(
                    shortcuts: ["#tag"],
                    description: rmbLocalized(.keyboardTypingShortcutsTagDescription),
                    highlightColor: .rmbColor(.tagHighlight)
                )
            }
        }
        .padding(20)
    }
}

private struct TypingShortcutRow: View {
    let shortcuts: [String]
    let description: String
    var highlightColor: Color = .primary

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            HStack(spacing: 4) {
                ForEach(shortcuts, id: \.self) { shortcut in
                    Text(shortcut)
                        .font(.system(.callout, design: .monospaced))
                        .foregroundColor(highlightColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(highlightColor.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
            .fixedSize(horizontal: true, vertical: false)
            .frame(width: 128, alignment: .leading)

            Text(description)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    KeyboardSettingsTab()
}
