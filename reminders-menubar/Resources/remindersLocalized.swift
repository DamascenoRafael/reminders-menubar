import Foundation

enum RemindersMenuBarLocalizedKeys: String {
    case newReminderTextFielPlaceholder
    case newReminderCalendarSelectionToSaveHelp
    case selectListForSavingReminderButtonHelp
    case newReminderAddDateButton
    case newReminderAddTimeButton
    case newReminderAutoSuggestTodayOption
    case newReminderRemoveParsedDateOption
    case remindersOptionsButtonHelp
    case editReminderOptionButton
    case editReminderTitleTextFieldPlaceholder
    case editReminderNotesTextFieldPlaceholder
    case editReminderRemindMeSection
    case editReminderRemindDateOption
    case editReminderRemindTimeOption
    case editReminderPrioritySection
    case editReminderListSection
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
    case upcomingRemindersTitle
    case remindersFilterSelectionHelp
    case showCompletedRemindersToggleButtonHelp
    case updateAvailableNoticeButton
    case launchAtLoginOptionButton
    case appAppearanceMenu
    case appAppearanceMoreOpaqueOptionButton
    case appAppearanceMoreTransparentOptionButton
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
    case keyboardShortcutOptionButton
    case reloadRemindersDataButton
    case appAboutButton
    case appQuitButton
    case settingsButtonHelp
    case aboutRemindersMenuBarWindowTitle
    case appVersionDescription
    case remindersMenuBarAppAboutDescription
    case remindersMenuBarGitHubAboutDescription
    case seeMoreOnGitHubButton
    case keyboardShortcutWindowTitle
    case keyboardShortcutEnableOpenShortcutOption
    case keyboardShortcutRestoreDefaultButton
    case upcomingRemindersIntervalSelectionHelp
    case upcomingRemindersDueTitle
    case upcomingRemindersTodayTitle
    case upcomingRemindersInAWeekTitle
    case upcomingRemindersInAMonthTitle
    case upcomingRemindersAllTitle
    case filterUpcomingRemindersByCalendarOptionButton // swiftlint:disable:this identifier_name
    case appNoRemindersAccessAlertMessage
    case appNoRemindersAccessAlertReasonDescription // swiftlint:disable:this identifier_name
    case appNoRemindersAccessAlertActionDescription // swiftlint:disable:this identifier_name
    case openSystemPreferencesButton
    case okButton
    case preferredLanguageMenu
    case preferredLanguageSystemOptionButton
    case reminderRecurrenceDailyLabel
    case reminderRecurrenceWeeklyLabel
    case reminderRecurrenceMonthlyLabel
    case reminderRecurrenceYearlyLabel
}

struct ReminderMenuBarLocale {
    let identifier: String
    let name: String
}

func rmbLocalized(_ key: RemindersMenuBarLocalizedKeys, arguments: CVarArg...) -> String {
    let preferredLanguage = rmbCurrentLocale().identifier
    let localeBundle: Bundle = {
        if let url = Bundle.main.url(forResource: preferredLanguage, withExtension: "lproj"),
           let bundle = Bundle(url: url) {
            return bundle
        }
        return .main
    }()

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

func rmbCurrentLocale() -> Locale {
    var currentLocale = Locale.current
    if let preferredLanguage = UserPreferences.shared.preferredLanguage {
        currentLocale = Locale(identifier: preferredLanguage)
    }
    
    return currentLocale
}
