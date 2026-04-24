import SwiftUI

struct MenuBarSettingsTab: View {
    @ObservedObject var userPreferences = UserPreferences.shared

    var body: some View {
        Form {
            SettingsSection(rmbLocalized(.menuBarIconSettingsLabel)) {
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

                let isMenuBarCounterDisabled = userPreferences.menuBarCounterType == .disabled
                Toggle(
                    rmbLocalized(.hideMenuBarIconWhenCounterIsShownOption),
                    isOn: Binding(
                        get: { userPreferences.hideMenuBarIconWhenCounterIsShown && !isMenuBarCounterDisabled },
                        set: { newValue in
                            userPreferences.hideMenuBarIconWhenCounterIsShown = newValue
                            AppDelegate.shared.loadMenuBarIcon()
                        }
                    )
                )
                .disabled(isMenuBarCounterDisabled)
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
                    rmbLocalized(.filterMenuBarCountByCalendarOption),
                    isOn: $userPreferences.filterMenuBarCountByCalendar
                )
            }
        }
        .padding(20)
    }
}

#Preview {
    MenuBarSettingsTab()
}
