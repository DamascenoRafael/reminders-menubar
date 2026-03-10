import SwiftUI

struct CopySettingsTab: View {
    @ObservedObject var userPreferences = UserPreferences.shared
    @State private var templateText: String = UserPreferences.shared.copyTemplate

    private let availableVariables = [
        "{title}", "{notes}", "{date}", "{priority}", "{list}", "{url}"
    ]

    var body: some View {
        Form {
            SettingsSection(rmbLocalized(.copyFormatTemplateLabel)) {
                TextField(
                    rmbLocalized(.copyFormatTemplateLabel),
                    text: $templateText
                )
                .labelsHidden()
                .textFieldStyle(.roundedBorder)
                .font(.system(.body, design: .monospaced))
                .onChange(of: templateText) { newValue in
                    userPreferences.copyTemplate = newValue
                }

                Text(rmbLocalized(.copyFormatTemplateHint, arguments: "\\n"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            SettingsDivider()

            SettingsSection(rmbLocalized(.copyFormatAvailableVariables)) {
                HStack(spacing: 6) {
                    ForEach(availableVariables, id: \.self) { variable in
                        Text(variable)
                            .font(.system(.caption, design: .monospaced))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.secondary.opacity(0.15))
                            .cornerRadius(4)
                    }
                }
            }

            SettingsDivider()

            SettingsSection {
                Toggle(rmbLocalized(.copyFormatTrimOption), isOn: $userPreferences.copyTrimEnabled)
            }

            SettingsDivider()

            SettingsSection(rmbLocalized(.copyFormatPreviewLabel)) {
                Text(previewText)
                    .font(.system(.body, design: .monospaced))
                    .padding(10)
                    .fixedSize(horizontal: false, vertical: true)
                    .background(Color.secondary.opacity(0.08))
                    .cornerRadius(6)
            }
        }
        .padding(20)
    }

    private var previewText: String {
        let text = ReminderCopyService.previewText(
            template: templateText,
            trim: userPreferences.copyTrimEnabled
        )
        return text.isEmpty ? " " : text
    }
}

#Preview {
    CopySettingsTab()
}
