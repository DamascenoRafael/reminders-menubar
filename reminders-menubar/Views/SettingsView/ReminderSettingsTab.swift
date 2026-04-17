import SwiftUI

struct ReminderSettingsTab: View {
    @ObservedObject var userPreferences = UserPreferences.shared

    var body: some View {
        Form {
            SettingsSection(rmbLocalized(.upcomingRemindersSettingsLabel)) {
                Picker(String(""), selection: $userPreferences.upcomingRemindersInterval) {
                    ForEach(ReminderInterval.allCases, id: \.self) { interval in
                        Text(interval.filterOption).tag(interval)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()

                Toggle(
                    rmbLocalized(.showUpcomingRemindersSettingsOption),
                    isOn: $userPreferences.showUpcomingReminders
                )

                Toggle(
                    rmbLocalized(.showUpcomingReminderListNameOption),
                    isOn: $userPreferences.showUpcomingReminderListName
                )

                Toggle(isOn: $userPreferences.filterUpcomingRemindersByCalendar) {
                    HStack {
                        Text(rmbLocalized(.filterUpcomingRemindersByCalendarOption))
                        Image(systemName: "line.horizontal.3.decrease.circle")
                    }
                }
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
                Toggle(
                    rmbLocalized(.showExternalLinksInReminderItemOption),
                    isOn: $userPreferences.showExternalLinksInReminderItem
                )
            }

            SettingsDivider()

            SettingsSection {
                Button(rmbLocalized(.reloadRemindersDataButton)) {
                    NotificationCenter.default.post(name: .remindersDataShouldUpdate, object: nil)
                }
            }
        }
        .padding(20)
    }
}

#Preview {
    ReminderSettingsTab()
}
