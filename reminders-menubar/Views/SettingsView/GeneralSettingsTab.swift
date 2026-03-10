import SwiftUI

struct GeneralSettingsTab: View {
    @ObservedObject var userPreferences = UserPreferences.shared
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        Form {
            SettingsSection {
                Toggle(
                    rmbLocalized(.launchAtLoginOptionButton),
                    isOn: $userPreferences.launchAtLoginIsEnabled
                )
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
                        get: { !userPreferences.backgroundIsTransparent || reduceTransparency },
                        set: { userPreferences.backgroundIsTransparent = !$0 }
                    )
                )
                .disabled(reduceTransparency)
            }

            SettingsDivider()

            SettingsSection(rmbLocalized(.menuBarIconSettingsMenu)) {
                Picker(String(""), selection: Binding(
                    get: { userPreferences.reminderMenuBarIcon },
                    set: { newIcon in
                        userPreferences.reminderMenuBarIcon = newIcon
                        AppDelegate.shared.loadMenuBarIcon()
                    }
                )) {
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
            }

            SettingsDivider()

            SettingsSection(rmbLocalized(.menuBarCounterSettingsMenu)) {
                Picker(String(""), selection: $userPreferences.menuBarCounterType) {
                    ForEach(RmbMenuBarCounterType.allCases, id: \.self) { counterType in
                        Text(counterType.title).tag(counterType)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()

                Toggle(
                    rmbLocalized(.filterMenuBarCountByCalendarOptionButton),
                    isOn: $userPreferences.filterMenuBarCountByCalendar
                )
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

            SettingsSection(rmbLocalized(.preferredLanguageMenu)) {
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
        }
        .padding(20)
    }
}

#Preview {
    GeneralSettingsTab()
}
