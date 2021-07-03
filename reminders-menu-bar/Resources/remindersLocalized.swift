import Foundation

enum RemindersMenuBarLocalizedKeys: String {
    case newReminderTextFielPlaceholder
    case newReminderCalendarSelectionToSaveHelp
    case remindersOptionsButtonHelp
    case removeReminderOptionButton
    case removeReminderAlertTitle
    case removeReminderAlertMessage
    case removeReminderAlertConfirmButton
    case removeReminderAlertCancelButton
    case reminderMoveToMenuOption
    case emptyListNoRemindersMessage
    case emptyListAllItemsCompletedMessage
    case emptyListNoUpcomingRemindersMessage
    case upcomingRemindersTitle
    case remindersFilterSelectionHelp
    case showCompletedRemindersToggleButtonHelp
    case updateAvaiableNoticeButton
    case launchAtLoginOptionButton
    case appAppearanceMenu
    case appAppearanceMoreOpaqueOptionButton
    case appAppearanceMoreTransparentOptionButton
    case showMenuBarTodayCountOptionButton
    case reloadRemindersDataButton
    case appAboutButton
    case appQuitButton
    case settingsButtonHelp
    case aboutRemindersMenuBarWindowTitle
    case appVersionDescription
    case remindersMenuBarAppAboutDescription
    case remindersMenuBarGitHubAboutDescription
    case seeMoreOnGitHubButton
    case upcomingRemindersIntervalSelectionHelp
    case upcomingRemindersTodayTitle
    case upcomingRemindersInAWeekTitle
    case upcomingRemindersInAMonthTitle
    case upcomingRemindersAllTitle
    case appNoRemindersAccessAlertMessage
    case appNoRemindersAccessAlertDescription
    case openSystemPreferencesButton
    case okButton
}

func rmbLocalized(_ key: RemindersMenuBarLocalizedKeys, arguments: CVarArg...) -> String {
    let localizedString = NSLocalizedString(key.rawValue, comment: "")
    return String(format: localizedString, arguments: arguments)
}

func rmbCurrentLocale() -> Locale {
    let currentLocale = Locale.current
    if Bundle.main.path(forResource: currentLocale.identifier, ofType: "lproj") == nil {
        // Return the default locale if translation to system language does not exist
        return Locale(identifier: "en_US")
    }
    
    return currentLocale
}
