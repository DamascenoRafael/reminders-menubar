import SwiftUI

struct SectionsSettingsTab: View {
    @ObservedObject var userPreferences = UserPreferences.shared
    @ObservedObject var reminderListSectionsService = ReminderListSectionsService.shared

    @State private var showingSectionsAccessAlert = false

    private var showReminderListSectionsBinding: Binding<Bool> {
        Binding(
            get: { userPreferences.showReminderListSections },
            set: { isOn in
                guard isOn else {
                    userPreferences.showReminderListSections = false
                    userPreferences.reminderListSectionsFolderBookmark = nil
                    return
                }
                if reminderListSectionsService.requestStoresFolderAccess() {
                    userPreferences.showReminderListSections = true
                } else {
                    showingSectionsAccessAlert = true
                }
            }
        )
    }

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
                    rmbLocalized(.hideUpcomingRemindersFromListsOption),
                    isOn: $userPreferences.hideUpcomingRemindersFromLists
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

            SettingsDivider()

            SettingsSection(rmbLocalized(.reminderListSectionsSettingsLabel)) {
                Toggle(
                    rmbLocalized(.showReminderListSectionsOption),
                    isOn: showReminderListSectionsBinding
                )

                Text(rmbLocalized(.showReminderListSectionsNote))
                    .modifier(SettingsNoteStyle())

                if userPreferences.showReminderListSections && reminderListSectionsService.isUnavailable {
                    Text(rmbLocalized(.reminderListSectionsUnavailableNote))
                        .modifier(SettingsNoteStyle())
                }
            }
        }
        .padding(20)
        .alert(isPresented: $showingSectionsAccessAlert) {
            Alert(
                title: Text(rmbLocalized(.reminderListSectionsAccessAlertTitle)),
                message: Text(rmbLocalized(.reminderListSectionsAccessAlertMessage)),
                dismissButton: .default(Text(rmbLocalized(.okButton)))
            )
        }
    }
}

#Preview {
    SectionsSettingsTab()
}
