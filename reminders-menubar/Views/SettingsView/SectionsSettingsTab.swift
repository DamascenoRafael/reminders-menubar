import SwiftUI

struct SectionsSettingsTab: View {
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
                        Image(rmbSymbol: .filterCircle)
                    }
                }
            }

            SettingsDivider()

            SettingsSection(rmbLocalized(.tagRemindersSettingsLabel)) {
                Toggle(
                    rmbLocalized(.showTagsBeforeCalendarsOption),
                    isOn: $userPreferences.showTagsBeforeCalendars
                )

                Toggle(isOn: $userPreferences.filterTagRemindersByCalendar) {
                    HStack {
                        Text(rmbLocalized(.filterTagRemindersByCalendarOption))
                        Image(rmbSymbol: .filterCircle)
                    }
                }
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
                    .modifier(SettingsNoteStyle())

                Toggle(
                    rmbLocalized(.reminderSortingDueDateOnTopOption),
                    isOn: $userPreferences.showRemindersWithDueDateOnTop
                )

                Text(rmbLocalized(.reminderSortingDueDateOnTopNote))
                    .modifier(SettingsNoteStyle())
                    .padding(.leading, 20)

                Toggle(
                    rmbLocalized(.reminderSortingByFlagAndPriorityOption),
                    isOn: $userPreferences.sortRemindersByFlagAndPriority
                )
            }
        }
        .padding(20)
    }
}

#Preview {
    SectionsSettingsTab()
}
