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

            SettingsSection(rmbLocalized(.reminderSortingSettingsLabel)) {
                Picker(String(""), selection: $userPreferences.reminderSortingOrder) {
                    ForEach(RmbSortingOrder.allCases, id: \.self) { sortingOrder in
                        Text(sortingOrder.title).tag(sortingOrder)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()

                Text(userPreferences.reminderSortingOrder.note)
                    .font(.caption)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 4)

                Toggle(
                    rmbLocalized(.reminderSortingDueDateOnTopOption),
                    isOn: $userPreferences.showRemindersWithDueDateOnTop
                )

                Text(rmbLocalized(.reminderSortingDueDateOnTopNote))
                    .font(.caption)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.leading, 20)
                    .padding(.bottom, 4)

                Toggle(
                    rmbLocalized(.reminderSortingByPriorityOption),
                    isOn: $userPreferences.sortRemindersByPriority
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

#Preview {
    ReminderSettingsTab()
}
