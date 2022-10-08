import Foundation

enum RemindersMenuBarLocalizedKeys: String {
    case newReminderTextFielPlaceholder
    case newReminderCalendarSelectionToSaveHelp
    case remindersOptionsButtonHelp
    case renameReminderOptionButton
    case renameReminderAlertTitle
    case renameReminderAlertMessage
    case renameReminderAlertConfirmButton
    case renameReminderAlertCancelButton
    case removeReminderOptionButton
    case removeReminderAlertTitle
    case removeReminderAlertMessage
    case removeReminderAlertConfirmButton
    case removeReminderAlertCancelButton
    case reminderMoveToMenuOption
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
    case showMenuBarTodayCountOptionButton
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
    case upcomingRemindersTodayTitle
    case upcomingRemindersInAWeekTitle
    case upcomingRemindersInAMonthTitle
    case upcomingRemindersAllTitle
    case appNoRemindersAccessAlertMessage
    case appNoRemindersAccessAlertDescription
    case openSystemPreferencesButton
    case okButton
    case preferredLanguageMenu
    case preferredLanguageSystemOptionButton
}

struct ReminderMenuBarLocale {
    let identifier: String
    let name: String
}

func rmbLocalized(_ key: RemindersMenuBarLocalizedKeys, arguments: CVarArg...) -> String {
    let preferredLanguage = rmbCurrentLocale().identifier
    let localePath = Bundle.main.path(forResource: preferredLanguage, ofType: "lproj") ?? ""
    let localeBundle = Bundle(path: localePath) ?? Bundle.main
    
    let localizedString = NSLocalizedString(key.rawValue, bundle: localeBundle, comment: "")
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
    if let preferredLanguage = UserPreferences.instance.preferredLanguage {
        currentLocale = Locale(identifier: preferredLanguage)
    }
    if Bundle.main.path(forResource: currentLocale.identifier, ofType: "lproj") == nil {
        // Return the default locale if translation to system language does not exist
        return Locale(identifier: "en_US")
    }
    
    return currentLocale
}
