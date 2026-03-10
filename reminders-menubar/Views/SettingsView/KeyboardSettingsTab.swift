import SwiftUI
import KeyboardShortcuts

struct KeyboardSettingsTab: View {
    @ObservedObject var keyboardShortcutService = KeyboardShortcutService.shared

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
        }
        .padding(20)
    }
}

#Preview {
    KeyboardSettingsTab()
}
