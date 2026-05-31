import SwiftUI

struct MenuBarSettingsTab: View {
    @ObservedObject var userPreferences = UserPreferences.shared

    var body: some View {
        Form {
            let isMenuBarCounterDisabled = userPreferences.menuBarCounterType == .disabled
            let isReminderPreviewDisabled = !userPreferences.menuBarReminderPreviewEnabled

            SettingsSection(rmbLocalized(.menuBarIconSettingsLabel)) {
                Picker(String(""), selection: $userPreferences.reminderMenuBarIcon) {
                    ForEach(RmbIcon.allCases, id: \.self) { icon in
                        HStack {
                            Image(nsImage: icon.image)
                            Text(icon.name)
                        }
                        .tag(icon)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()

                Toggle(
                    rmbLocalized(.hideMenuBarIconWhenContentIsShownOption),
                    isOn: Binding(
                        get: {
                            userPreferences.hideMenuBarIconWhenContentIsShown
                            && (!isMenuBarCounterDisabled || !isReminderPreviewDisabled)
                        },
                        set: { newValue in
                            userPreferences.hideMenuBarIconWhenContentIsShown = newValue
                        }
                    )
                )
                .disabled(isMenuBarCounterDisabled && isReminderPreviewDisabled)
            }

            SettingsDivider()

            SettingsSection {
                Toggle(
                    rmbLocalized(.filterMenuBarContentByCalendarOption),
                    isOn: $userPreferences.filterMenuBarContentByCalendar
                )
            }

            SettingsDivider()

            SettingsSection(rmbLocalized(.menuBarCounterSettingsLabel)) {
                Picker(String(""), selection: $userPreferences.menuBarCounterType) {
                    ForEach(RmbMenuBarCounterType.allCases, id: \.self) { counterType in
                        Text(counterType.title).tag(counterType)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()

                Toggle(
                    rmbLocalized(.hideCounterWhenPreviewShownOption),
                    isOn: $userPreferences.hideCounterWhenReminderPreviewIsShown
                )
                .disabled(isReminderPreviewDisabled)
            }

            SettingsDivider()

            SettingsSection(rmbLocalized(.menuBarPreviewSettingsLabel)) {
                Toggle(
                    rmbLocalized(.menuBarPreviewEnableOption),
                    isOn: $userPreferences.menuBarReminderPreviewEnabled
                )

                HStack {
                    Text(rmbLocalized(.menuBarPreviewTimeAheadLabel))

                    Picker(String(""), selection: $userPreferences.menuBarReminderPreviewTimeAhead) {
                        ForEach(RmbMenuBarPreviewTimeAhead.allCases, id: \.self) { timeAhead in
                            Text(timeAhead.title).tag(timeAhead)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .disabled(isReminderPreviewDisabled)
                }
                .padding(.leading, 20)

                Text(rmbLocalized(.menuBarPreviewGracePeriodNote))
                    .modifier(SettingsNoteStyle())
                    .padding(.leading, 20)

                HStack {
                    Text(rmbLocalized(.menuBarPreviewMaxLengthLabel))
                    Slider(
                        value: Binding(
                            get: { Double(userPreferences.menuBarReminderPreviewMaxLength) },
                            set: { userPreferences.menuBarReminderPreviewMaxLength = Int($0) }
                        ),
                        in: 5...30,
                        step: 5
                    )
                    .labelsHidden()
                    .disabled(isReminderPreviewDisabled)
                    .frame(maxWidth: 260)

                    Text(String(userPreferences.menuBarReminderPreviewMaxLength))
                        .foregroundColor(.secondary)
                        .opacity(isReminderPreviewDisabled ? 0.4 : 1.0)
                        .frame(minWidth: 20, alignment: .trailing)
                }
                .padding(.leading, 20)
                .padding(.bottom, 8)

                Toggle(
                    rmbLocalized(.menuBarPreviewShowTodayOption),
                    isOn: $userPreferences.menuBarReminderPreviewShowTodayReminders
                )
                .disabled(isReminderPreviewDisabled)
            }
        }
        .padding(20)
    }
}

#Preview {
    MenuBarSettingsTab()
}
