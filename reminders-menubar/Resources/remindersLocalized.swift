import Foundation

enum RemindersMenuBarLocalizedKeys: String {
    case newReminderSettingsLabel
    case newReminderAutoSuggestTodayOption
    case newReminderRemoveParsedDateOption
    case remindersOptionsButtonHelp
    case editReminderButton
    case editReminderTitleTextFieldPlaceholder
    case editReminderExternalLinksViewOnlyLabel
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
    case removeReminderButton
    case removeReminderAlertTitle
    case removeReminderAlertMessage
    case removeReminderAlertConfirmButton
    case removeReminderAlertCancelButton
    case emptyListNoCalendarsTitle
    case emptyListNoCalendarsMessage
    case emptyListAllItemsCompletedMessage
    case emptyListNoRemindersFilterTitle
    case emptyListNoRemindersFilterMessage
    case emptyListNoUpcomingRemindersMessage
    case emptyListNoRecentRemindersMessage
    case upcomingRemindersButton
    case upcomingRemindersSettingsLabel
    case remindersFilterSelectionHelp
    case recentRemindersButtonHelp
    case recentRemindersSectionTitle
    case showMoreRemindersButton
    case recentRemindersLoadingMessage
    case updateAvailableNoticeButton
    case launchAtLoginOption
    case appAppearanceReduceTransparencyOption
    case appColorSchemeSettingsLabel
    case appAppearanceColorSystemModeOption
    case appAppearanceColorLightModeOption
    case appAppearanceColorDarkModeOption
    case menuBarIconSettingsLabel
    case menuBarCounterSettingsLabel
    case filterMenuBarCountByCalendarOption
    case showMenuBarDueCountOption
    case showMenuBarTodayCountOption
    case showMenuBarAllRemindersCountOption
    case showMenuBarNoCountOption
    case reloadRemindersDataButton
    case appAboutButton
    case appQuitButton
    case appSettingsButton
    case settingsButtonHelp
    case appVersionDescription
    case remindersMenuBarAppAboutDescription
    case seeMoreOnGitHubButton
    case checkForUpdatesButton
    case updateAvailableAlertTitle
    case updateAvailableAlertMessage
    case upToDateAlertTitle
    case upToDateAlertMessage
    case openAppStoreButton
    case updateLaterButton
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
    case filterUpcomingRemindersByCalendarOption // swiftlint:disable:this identifier_name
    case appNoRemindersAccessAlertMessage
    case appNoRemindersAccessAlertReasonDescription // swiftlint:disable:this identifier_name
    case appNoRemindersAccessAlertActionDescription // swiftlint:disable:this identifier_name
    case openSystemPreferencesButton
    case openAppleRemindersButton
    case okButton
    case preferredLanguageSettingsLabel
    case preferredLanguageSystemSettingsOption
    case reminderRecurrenceDailyLabel
    case reminderRecurrenceWeeklyLabel
    case reminderRecurrenceMonthlyLabel
    case reminderRecurrenceYearlyLabel
    case copyReminderButton
    case copiedToastMessage
    case reminderEditPopoverSaveButton
    case newReminderButtonHelp
    case copyPreviewSettingsLabel
    case copyPropertiesSettingsLabel
    case copyPropertiesSettingsNote
    case copyIncludePropertyNamesOption
    case copyNoPropertiesSelectedNote
    case copyPropertyTitle
    case copyPropertyNotes
    case copyPropertyDate
    case copyPropertyPriority
    case copyPropertyList
    case copyPropertyUrl
    case copyPropertyEnabledAccessibilityValue
    case copyPropertyDisabledAccessibilityValue
    case movePropertyUpAccessibilityLabel
    case movePropertyDownAccessibilityLabel
    case copySampleTitle
    case copySampleNotes
    case copySampleList
    case showUpcomingRemindersSettingsOption
    case showExternalLinksInReminderItemOption
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
    case searchRemindersButtonHelp
    case searchRemindersPlaceholder
    case searchRemindersLoadingMessage
    case emptyListSearchNoQueryMessage
    case emptyListSearchNoResultsMessage
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
