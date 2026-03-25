import Foundation

enum RemindersMenuBarLocalizedKeys: String {
    case newReminderSettingsLabel
    case newReminderAutoSuggestTodayOption
    case newReminderRemoveParsedDateOption
    case remindersOptionsButtonHelp
    case editReminderOptionButton
    case editReminderTitleTextFieldPlaceholder
    case editReminderNotesTextFieldPlaceholder
    case newReminderAddDateButton
    case newReminderAddTimeButton
    case changeReminderListMenuOption
    case changeReminderDueDateMenuOption
    case editReminderDueDateTodayOption
    case editReminderDueDateTomorrowOption
    case editReminderDueDateThisWeekendOption
    case editReminderDueDateNextWeekOption
    case editReminderDueDateNoneOption
    case changeReminderPriorityMenuOption
    case editReminderPriorityLowOption
    case editReminderPriorityMediumOption
    case editReminderPriorityHighOption
    case editReminderPriorityNoneOption
    case removeReminderOptionButton
    case removeReminderAlertTitle
    case removeReminderAlertMessage
    case removeReminderAlertConfirmButton
    case removeReminderAlertCancelButton
    case emptyListNoRemindersMessage
    case emptyListNoRemindersFilterTitle
    case emptyListNoRemindersFilterMessage
    case emptyListAllItemsCompletedMessage
    case emptyListNoUpcomingRemindersMessage
    case upcomingRemindersButton
    case upcomingRemindersSettingsLabel
    case remindersFilterSelectionHelp
    case showCompletedRemindersToggleButtonHelp
    case updateAvailableNoticeButton
    case launchAtLoginOptionButton
    case appAppearanceReduceTransparencyOption
    case appColorSchemeSettingsLabel
    case appAppearanceColorSystemModeOptionButton
    case appAppearanceColorLightModeOptionButton
    case appAppearanceColorDarkModeOptionButton
    case menuBarIconSettingsMenu
    case menuBarCounterSettingsMenu
    case filterMenuBarCountByCalendarOptionButton
    case showMenuBarDueCountOptionButton
    case showMenuBarTodayCountOptionButton
    case showMenuBarAllRemindersCountOptionButton
    case showMenuBarNoCountOptionButton
    case reloadRemindersDataButton
    case appAboutButton
    case appQuitButton
    case appSettingsButton
    case settingsButtonHelp
    case appVersionDescription
    case remindersMenuBarAppAboutDescription
    case remindersMenuBarGitHubAboutDescription
    case seeMoreOnGitHubButton
    case keyboardShortcutEnableOpenShortcutOption
    case keyboardShortcutRestoreDefaultButton
    case upcomingRemindersDueFilterOption
    case upcomingRemindersTodayFilterOption
    case upcomingRemindersInAWeekFilterOption
    case upcomingRemindersInAMonthFilterOption
    case upcomingRemindersAllFilterOption
    case upcomingRemindersDueSectionTitle
    case upcomingRemindersTodaySectionTitle
    case upcomingRemindersInAWeekSectionTitle
    case upcomingRemindersInAMonthSectionTitle
    case upcomingRemindersScheduledSectionTitle
    case upcomingRemindersFilterByCalendarEnabledHelp // swiftlint:disable:this identifier_name
    case filterUpcomingRemindersByCalendarOptionButton // swiftlint:disable:this identifier_name
    case appNoRemindersAccessAlertMessage
    case appNoRemindersAccessAlertReasonDescription // swiftlint:disable:this identifier_name
    case appNoRemindersAccessAlertActionDescription // swiftlint:disable:this identifier_name
    case openSystemPreferencesButton
    case okButton
    case preferredLanguageMenu
    case preferredLanguageSystemSettingsOption
    case reminderRecurrenceDailyLabel
    case reminderRecurrenceWeeklyLabel
    case reminderRecurrenceMonthlyLabel
    case reminderRecurrenceYearlyLabel
    case copyReminderOptionButton
    case copiedToastMessage
    case reminderEditPopoverSaveButton
    case newReminderButtonHelp
    case copyFormatTemplateLabel
    case copyFormatTemplateHint
    case copyFormatAvailableVariables
    case copyFormatTrimOption
    case copyFormatPreviewLabel
    case showUpcomingRemindersSettingsOption
    case showUpcomingReminderListNameOption
    case dragToResizeHelp
    case popoverSizeSettingsLabel
    case popoverSizeResetToDefaultButton
    case reminderSortingSettingsLabel
    case reminderSortingDueDateOnTopOption
    case reminderSortingDueDateOnTopNote
    case reminderSortingByPriorityOption
    case reminderSortingDefaultOrderOption
    case reminderSortingDefaultOrderNote
    case reminderSortingNewestFirstOption
    case reminderSortingNewestFirstNote
    case reminderSortingOldestFirstOption
    case reminderSortingOldestFirstNote
    case timeFormatSettingsLabel
    case timeFormat12HourOption
    case timeFormat24HourOption
    case generalSettingsTab
    case remindersSettingsTab
    case copySettingsTab
    case keyboardSettingsTab
    case aboutSettingsTab
}

struct ReminderMenuBarLocale {
    let identifier: String
    let name: String
}

func rmbLocalized(_ key: RemindersMenuBarLocalizedKeys, arguments: CVarArg...) -> String {
    let preferredLanguage = rmbCurrentLocale().identifier
    let localePath = Bundle.main.path(forResource: preferredLanguage, ofType: "lproj") ?? ""
    let localeBundle = Bundle(path: localePath) ?? Bundle.main
    
    let fallbackString = Bundle.main.localizedString(forKey: key.rawValue, value: nil, table: nil)
    let localizedString = localeBundle.localizedString(forKey: key.rawValue, value: fallbackString, table: nil)
    return String(format: localizedString, arguments: arguments)
}

func rmbAvailableLocales() -> [ReminderMenuBarLocale] {
    let currentLocale = rmbCurrentLocale()
    
    let locales = Bundle.main.localizations.compactMap { identifier -> ReminderMenuBarLocale? in
        guard let name = currentLocale.localizedString(forIdentifier: identifier) else {
            return nil
        }
        return ReminderMenuBarLocale(identifier: identifier, name: name.capitalized)
    }
    
    return locales.sorted(by: { $0.name < $1.name })
}

func rmbTimeFormattedLocale() -> Locale {
    let base = rmbCurrentLocale()
    let hourCycle = UserPreferences.shared.timeFormatIs24Hour ? "h23" : "h12"
    return Locale(identifier: "\(base.identifier)@hours=\(hourCycle)")
}

private func rmbCurrentLocale() -> Locale {
    var currentLocale = Locale.current
    if let preferredLanguage = UserPreferences.shared.preferredLanguage {
        currentLocale = Locale(identifier: preferredLanguage)
    }

    return currentLocale
}
