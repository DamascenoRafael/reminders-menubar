import SwiftUI

struct CopySettingsTab: View {
    @ObservedObject var userPreferences = UserPreferences.shared

    var body: some View {
        Form {
            SettingsSection(rmbLocalized(.copyPropertiesSettingsLabel)) {
                VStack(spacing: 0) {
                    let copyPropertyOptionsEnumerated = Array(userPreferences.copyPropertyOptions.enumerated())
                    ForEach(copyPropertyOptionsEnumerated, id: \.element.id) { index, option in
                        if index > 0 {
                            Divider()
                        }
                        CopyPropertyRow(
                            option: option,
                            isFirst: index == 0,
                            isLast: index == userPreferences.copyPropertyOptions.count - 1,
                            onToggle: {
                                userPreferences.copyPropertyOptions[index].isEnabled.toggle()
                            },
                            onMoveUp: {
                                moveOption(from: index, direction: -1)
                            },
                            onMoveDown: {
                                moveOption(from: index, direction: 1)
                            }
                        )
                    }
                }
                .frame(maxWidth: 250)
                .background(Color.secondary.opacity(0.08))
                .cornerRadius(8)

                Text(rmbLocalized(.copyPropertiesSettingsNote))
                    .modifier(SettingsNoteStyle())
                    .padding(.bottom, 6)

                Toggle(rmbLocalized(.copyIncludePropertyNamesOption), isOn: $userPreferences.copyIncludePropertyNames)
            }

            SettingsDivider()

            SettingsSection(rmbLocalized(.copyPreviewSettingsLabel)) {
                if hasEnabledOptions {
                    Text(previewText)
                        .font(.system(.body, design: .monospaced))
                        .padding(10)
                        .fixedSize(horizontal: false, vertical: true)
                        .background(Color.secondary.opacity(0.08))
                        .cornerRadius(8)
                } else {
                    Text(rmbLocalized(.copyNoPropertiesSelectedNote))
                        .modifier(SettingsNoteStyle())
                }
            }
        }
        .padding(20)
    }

    private func moveOption(from index: Int, direction: Int) {
        let newIndex = index + direction
        guard newIndex >= 0 && newIndex < userPreferences.copyPropertyOptions.count else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            userPreferences.copyPropertyOptions.swapAt(index, newIndex)
        }
    }

    private var hasEnabledOptions: Bool {
        userPreferences.copyPropertyOptions.contains(where: \.isEnabled)
    }

    private var previewText: String {
        ReminderCopyService.previewText(
            options: userPreferences.copyPropertyOptions,
            includePropertyNames: userPreferences.copyIncludePropertyNames
        )
    }
}

private struct CopyPropertyRow: View {
    let option: CopyPropertyOption
    let isFirst: Bool
    let isLast: Bool
    let onToggle: () -> Void
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void

    var body: some View {
        HStack {
            Button(action: onToggle) {
                Image(systemName: option.isEnabled ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(option.isEnabled ? .accentColor : .secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(option.property.displayName)
            .accessibilityValue(rmbLocalized(
                option.isEnabled
                    ? .copyPropertyEnabledAccessibilityValue
                    : .copyPropertyDisabledAccessibilityValue
            ))

            Text(option.property.displayName)
                .foregroundColor(option.isEnabled ? .primary : .secondary)

            Spacer()

            HStack(spacing: 2) {
                Button(action: onMoveUp) {
                    Image(systemName: "chevron.up")
                        .font(.caption)
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(isFirst)
                .opacity(isFirst ? 0.3 : 1)
                .accessibilityLabel(
                    rmbLocalized(.movePropertyUpAccessibilityLabel, arguments: option.property.displayName)
                )

                Button(action: onMoveDown) {
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(isLast)
                .opacity(isLast ? 0.3 : 1)
                .accessibilityLabel(
                    rmbLocalized(.movePropertyDownAccessibilityLabel, arguments: option.property.displayName)
                )
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 2)
    }
}

#Preview {
    CopySettingsTab()
}
