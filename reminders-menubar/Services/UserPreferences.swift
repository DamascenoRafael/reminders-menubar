import SwiftUI
import ServiceManagement

private enum PreferencesKeys {
    static let reminderMenuBarIcon = "reminderMenuBarIcon"
    static let calendarIdentifiersFilter = "calendarIdentifiersFilter"
    static let calendarIdentifierForSaving = "calendarIdentifierForSaving"
    static let autoSuggestTodayForNewReminders = "autoSuggestTodayForNewReminders"
    static let removeParsedDateFromTitle = "removeParsedDateFromTitle"
    static let showUncompletedOnly = "showUncompletedOnly"
    static let rmbColorScheme = "rmbColorScheme"
    static let backgroundIsTransparent = "backgroundIsTransparent"
    static let showUpcomingReminders = "showUpcomingReminders"
    static let upcomingRemindersInterval = "upcomingRemindersInterval"
    static let filterUpcomingRemindersByCalendar = "filterUpcomingRemindersByCalendar"
    static let menuBarCounterType = "menuBarCounterType"
    static let filterMenuBarCountByCalendar = "filterMenuBarCountByCalendar"
    static let preferredLanguage = "preferredLanguage"
    static let copyTemplate = "copyTemplate"
    static let copyTrimEnabled = "copyTrimEnabled"
    static let mainPopoverHeight = "mainPopoverHeight"
    static let mainPopoverWidth = "mainPopoverWidth"
}

class UserPreferences: ObservableObject {
    static private(set) var shared = UserPreferences()
    
    private init() {
        // This prevents others from using the default '()' initializer for this class.
    }
    
    private static let defaults = UserDefaults.standard
    
    @Published var remindersMenuBarOpeningEvent = false
    
    @Published var reminderMenuBarIcon: RmbIcon = {
        guard let menuBarIconString = defaults.string(forKey: PreferencesKeys.reminderMenuBarIcon) else {
            return RmbIcon.defaultIcon
        }
        return RmbIcon(rawValue: menuBarIconString) ?? RmbIcon.defaultIcon
    }() {
        didSet {
            UserPreferences.defaults.set(reminderMenuBarIcon.rawValue, forKey: PreferencesKeys.reminderMenuBarIcon)
        }
    }
    
    var preferredCalendarIdentifiersFilter: [String]? {
        get {
            return UserPreferences.defaults.stringArray(forKey: PreferencesKeys.calendarIdentifiersFilter)
        }
        set {
            UserPreferences.defaults.set(newValue, forKey: PreferencesKeys.calendarIdentifiersFilter)
        }
    }
    
    var preferredCalendarIdentifierForSaving: String? {
        get {
            return UserPreferences.defaults.string(forKey: PreferencesKeys.calendarIdentifierForSaving)
        }
        set {
            UserPreferences.defaults.set(newValue, forKey: PreferencesKeys.calendarIdentifierForSaving)
        }
    }
    
    @Published var autoSuggestToday: Bool = {
        return defaults.bool(forKey: PreferencesKeys.autoSuggestTodayForNewReminders)
    }() {
        didSet {
            UserPreferences.defaults.set(autoSuggestToday, forKey: PreferencesKeys.autoSuggestTodayForNewReminders)
        }
    }
    
    @Published var removeParsedDateFromTitle: Bool = {
        return defaults.boolWithDefaultValueTrue(forKey: PreferencesKeys.removeParsedDateFromTitle)
    }() {
        didSet {
            UserPreferences.defaults.set(removeParsedDateFromTitle, forKey: PreferencesKeys.removeParsedDateFromTitle)
        }
    }
    
    @Published var showUncompletedOnly: Bool = {
        return defaults.boolWithDefaultValueTrue(forKey: PreferencesKeys.showUncompletedOnly)
    }() {
        didSet {
            UserPreferences.defaults.set(showUncompletedOnly, forKey: PreferencesKeys.showUncompletedOnly)
        }
    }
    
    @Published var upcomingRemindersInterval: ReminderInterval = {
        guard let intervalData = defaults.data(forKey: PreferencesKeys.upcomingRemindersInterval),
              let interval = try? JSONDecoder().decode(ReminderInterval.self, from: intervalData) else {
            return .today
        }
        return interval
    }() {
        didSet {
            let intervalData = try? JSONEncoder().encode(upcomingRemindersInterval)
            UserPreferences.defaults.set(intervalData, forKey: PreferencesKeys.upcomingRemindersInterval)
        }
    }
    
    @Published var filterUpcomingRemindersByCalendar: Bool = {
        return defaults.bool(forKey: PreferencesKeys.filterUpcomingRemindersByCalendar)
    }() {
        didSet {
            UserPreferences.defaults.set(
                filterUpcomingRemindersByCalendar,
                forKey: PreferencesKeys.filterUpcomingRemindersByCalendar
            )
        }
    }
    
    @Published var showUpcomingReminders: Bool = {
        return defaults.boolWithDefaultValueTrue(forKey: PreferencesKeys.showUpcomingReminders)
    }() {
        didSet {
            UserPreferences.defaults.set(showUpcomingReminders, forKey: PreferencesKeys.showUpcomingReminders)
        }
    }
    
    var atLeastOneFilterIsSelected: Bool {
        return
            showUpcomingReminders ||
            preferredCalendarIdentifiersFilter == nil ||
            !(preferredCalendarIdentifiersFilter ?? []).isEmpty
    }
    
    var launchAtLoginIsEnabled: Bool {
        get {
            let allJobs = SMCopyAllJobDictionaries(kSMDomainUserLaunchd).takeRetainedValue() as? [[String: AnyObject]]
            let launcherJob = allJobs?.first { $0["Label"] as? String == AppConstants.launcherBundleId }
            return launcherJob?["OnDemand"] as? Bool ?? false
        }
        
        set {
            SMLoginItemSetEnabled(AppConstants.launcherBundleId as CFString, newValue)
        }
    }
    
    @Published var rmbColorScheme: RmbColorScheme = {
        guard let rmbColorSchemeString = defaults.string(forKey: PreferencesKeys.rmbColorScheme) else {
            return .system
        }
        return RmbColorScheme(rawValue: rmbColorSchemeString) ?? .system
    }() {
        didSet {
            UserPreferences.defaults.set(rmbColorScheme.rawValue, forKey: PreferencesKeys.rmbColorScheme)
        }
    }
    
    @Published var backgroundIsTransparent: Bool = {
        return defaults.boolWithDefaultValueTrue(forKey: PreferencesKeys.backgroundIsTransparent)
    }() {
        didSet {
            UserPreferences.defaults.set(backgroundIsTransparent, forKey: PreferencesKeys.backgroundIsTransparent)
        }
    }
    
    @Published var menuBarCounterType: RmbMenuBarCounterType = {
        guard let counterTypeData = defaults.data(forKey: PreferencesKeys.menuBarCounterType),
              let counterType = try? JSONDecoder().decode(RmbMenuBarCounterType.self, from: counterTypeData) else {
            return .today
        }
        return counterType
    }() {
        didSet {
            let counterTypeData = try? JSONEncoder().encode(menuBarCounterType)
            UserPreferences.defaults.set(counterTypeData, forKey: PreferencesKeys.menuBarCounterType)
        }
    }
    
    @Published var filterMenuBarCountByCalendar: Bool = {
        return defaults.bool(forKey: PreferencesKeys.filterMenuBarCountByCalendar)
    }() {
        didSet {
            UserPreferences.defaults.set(
                filterMenuBarCountByCalendar,
                forKey: PreferencesKeys.filterMenuBarCountByCalendar
            )
        }
    }
    
    @Published var copyTemplate: String = {
        return defaults.string(forKey: PreferencesKeys.copyTemplate) ?? "{title}"
    }() {
        didSet {
            UserPreferences.defaults.set(copyTemplate, forKey: PreferencesKeys.copyTemplate)
        }
    }

    @Published var copyTrimEnabled: Bool = {
        return defaults.boolWithDefaultValueTrue(forKey: PreferencesKeys.copyTrimEnabled)
    }() {
        didSet {
            UserPreferences.defaults.set(copyTrimEnabled, forKey: PreferencesKeys.copyTrimEnabled)
        }
    }

    @Published var preferredLanguage: String? = {
        return defaults.string(forKey: PreferencesKeys.preferredLanguage)
    }() {
        didSet {
            UserPreferences.defaults.set(preferredLanguage, forKey: PreferencesKeys.preferredLanguage)
        }
    }

    // Stored as a CGFloat-backed Double for window sizing. This is intentionally not @Published;
    // it is used for persistence and for driving the NSPopover size directly.
    var mainPopoverHeight: CGFloat {
        get {
            let raw = UserPreferences.defaults.double(forKey: PreferencesKeys.mainPopoverHeight)
            return raw > 0 ? CGFloat(raw) : 460
        }
        set {
            UserPreferences.defaults.set(Double(newValue), forKey: PreferencesKeys.mainPopoverHeight)
        }
    }

    var mainPopoverWidth: CGFloat {
        get {
            let raw = UserPreferences.defaults.double(forKey: PreferencesKeys.mainPopoverWidth)
            return raw > 0 ? CGFloat(raw) : 340
        }
        set {
            UserPreferences.defaults.set(Double(newValue), forKey: PreferencesKeys.mainPopoverWidth)
        }
    }
}
