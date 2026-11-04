import SwiftUI

struct GeneralSettingsTab: View {
    @ObservedObject var userPreferences = UserPreferences.shared
    @ObservedObject private var launchAtLoginService = LaunchAtLoginService.shared

    var body: some View {
        Form {
            SettingsSection {
                Toggle(
                    rmbLocalized(.launchAtLoginOption),
                    isOn: Binding(
                        get: { launchAtLoginService.isEnabled },
                        set: { launchAtLoginService.setEnabled($0) }
                    )
                )
                .disabled(launchAtLoginService.status == .unavailable)

                launchAtLoginStatusNote
            }

            SettingsDivider()

            SettingsSection(rmbLocalized(.appColorSchemeSettingsLabel)) {
                Picker(String(""), selection: $userPreferences.rmbColorScheme) {
                    Text(RmbColorScheme.system.title).tag(RmbColorScheme.system)
                    Divider()
                    Text(RmbColorScheme.light.title).tag(RmbColorScheme.light)
                    Text(RmbColorScheme.dark.title).tag(RmbColorScheme.dark)
                }
                .pickerStyle(.menu)
                .labelsHidden()

                Toggle(
                    rmbLocalized(.appAppearanceReduceTransparencyOption),
                    isOn: Binding(
                        get: { !userPreferences.preferTransparentBackground || userPreferences.reduceTransparency },
                        set: { userPreferences.preferTransparentBackground = !$0 }
                    )
                )
                .disabled(userPreferences.reduceTransparency)
            }

            SettingsDivider()

            SettingsSection(rmbLocalized(.popoverSizeSettingsLabel)) {
                Button(action: {
                    let defaultSize = MainPopoverSizing.defaultSize
                    AppDelegate.shared.setMainPopoverSize(size: defaultSize, persist: true)
                }) {
                    Text(rmbLocalized(.popoverSizeResetToDefaultButton))
                }
            }

            SettingsDivider()

            SettingsSection(rmbLocalized(.preferredLanguageSettingsLabel)) {
                Picker(String(""), selection: Binding(
                    get: { userPreferences.preferredLanguage ?? "" },
                    set: { newValue in
                        userPreferences.preferredLanguage = newValue.isEmpty ? nil : newValue
                    }
                )) {
                    Text(rmbLocalized(.preferredLanguageSystemSettingsOption))
                        .tag("")
                    Divider()
                    ForEach(rmbAvailableLocales(), id: \.identifier) { locale in
                        Text(locale.name)
                            .tag(locale.identifier)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }

            SettingsSection(rmbLocalized(.timeFormatSettingsLabel)) {
                Picker(String(""), selection: $userPreferences.timeFormatIs24Hour) {
                    Text(rmbLocalized(.timeFormat12HourOption)).tag(false)
                    Text(rmbLocalized(.timeFormat24HourOption)).tag(true)
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }

            SettingsSection(rmbLocalized(.firstWeekdaySettingsLabel)) {
                Picker(String(""), selection: $userPreferences.firstWeekday) {
                    Text(rmbLocalized(.firstWeekdaySystemOption)).tag(Int?.none)
                    Divider()
                    ForEach(Array(rmbWeekdaySymbols().enumerated()), id: \.element) { index, weekday in
                        Text(weekday).tag(Optional(index + 1))
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }

            SettingsDivider()

            SettingsSection {
                Button(rmbLocalized(.reloadRemindersDataButton)) {
                    NotificationCenter.default.post(name: .remindersDataShouldUpdate, object: nil)
                }
            }
        }
        .padding(20)
        .onAppear {
            launchAtLoginService.refresh()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            launchAtLoginService.refresh()
        }
    }

    @ViewBuilder private var launchAtLoginStatusNote: some View {
        switch launchAtLoginService.status {
        case .requiresApproval:
            Text(rmbLocalized(.launchAtLoginApprovalRequiredNote))
                .modifier(SettingsNoteStyle())

            if #available(macOS 13.0, *) {
                Button(rmbLocalized(.openLoginItemsSettingsButton)) {
                    launchAtLoginService.openSystemSettings()
                }
            }
        case .unavailable:
            Text(rmbLocalized(.launchAtLoginUnavailableNote))
                .modifier(SettingsNoteStyle())
        case .enabled, .disabled:
            EmptyView()
        }
    }
}

#Preview {
    GeneralSettingsTab()
}
