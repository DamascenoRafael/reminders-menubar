import SwiftUI

struct ReminderSettingsTab: View {
    @ObservedObject var userPreferences = UserPreferences.shared

    var body: some View {
        Form {
            SettingsSection {
                Toggle(
                    rmbLocalized(.showUpcomingRemindersSettingsOption),
                    isOn: $userPreferences.showUpcomingReminders
                )
            }

            SettingsDivider()

            SettingsSection(rmbLocalized(.newReminderSettingsLabel)) {
                Toggle(
                    rmbLocalized(.newReminderAutoSuggestTodayOption),
                    isOn: $userPreferences.autoSuggestToday
                )
                Toggle(
                    rmbLocalized(.newReminderRemoveParsedDateOption),
                    isOn: $userPreferences.removeParsedDateFromTitle
                )
            }

            SettingsDivider()

            SettingsSection {
                Button(rmbLocalized(.reloadRemindersDataButton)) {
                    UserPreferences.shared.remindersMenuBarOpeningEvent.toggle()
                }
            }
        }
        .padding(20)
    }
}
