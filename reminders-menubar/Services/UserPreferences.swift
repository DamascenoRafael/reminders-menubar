import SwiftUI
import ServiceManagement

private enum PreferencesKeys {
    static let reminderMenuBarIcon = "reminderMenuBarIcon"
    static let calendarIdentifiersFilter = "calendarIdentifiersFilter"
    static let calendarIdentifierForSaving = "calendarIdentifierForSaving"
    static let autoSuggestTodayForNewReminders = "autoSuggestTodayForNewReminders"
    static let removeParsedDateFromTitle = "removeParsedDateFromTitle"
    static let rmbColorScheme = "rmbColorScheme"
    static let preferTransparentBackground = "backgroundIsTransparent"
    static let showUpcomingReminders = "showUpcomingReminders"
    static let upcomingRemindersInterval = "upcomingRemindersInterval"
    static let filterUpcomingRemindersByCalendar = "filterUpcomingRemindersByCalendar"
    static let menuBarCounterType = "menuBarCounterType"
    static let filterMenuBarContentByCalendar = "filterMenuBarCountByCalendar"
    static let hideMenuBarIconWhenContentIsShown = "hideMenuBarIconWhenCounterIsShown"
    static let preferredLanguage = "preferredLanguage"
    static let copyProperties = "copyProperties"
    static let copyIncludePropertyNames = "copyIncludePropertyNames"
    static let mainPopoverSize = "mainPopoverSize"
    static let showUpcomingReminderListName = "showUpcomingReminderListName"
    static let showRemindersWithDueDateOnTop = "showRemindersWithDueDateOnTop"
    static let sortRemindersByPriority = "sortRemindersByPriority"
    static let reminderSortingOrder = "reminderSortingOrder"
    static let timeFormatIs24Hour = "timeFormatIs24Hour"
    static let showExternalLinksInReminderItem = "showExternalLinksInReminderItem"
    static let menuBarReminderPreviewEnabled = "menuBarReminderPreviewEnabled"
    static let menuBarReminderPreviewTimeAhead = "menuBarReminderPreviewTimeAhead"
    static let menuBarReminderPreviewMaxLength = "menuBarReminderPreviewMaxLength"
    static let hideCounterWhenReminderPreviewIsShown = "hideCounterWhenReminderPreviewIsShown"
    static let menuBarReminderPreviewShowTodayReminders = "menuBarReminderPreviewShowTodayReminders"
}

class UserPreferences: ObservableObject {
    static let shared = UserPreferences()

    private var accessibilityObserver: NSObjectProtocol?

    private init() {
        accessibilityObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.accessibilityDisplayOptionsDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.reduceTransparency = NSWorkspace.shared.accessibilityDisplayShouldReduceTransparency
        }
    }

    deinit {
        if let observer = accessibilityObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    private static let defaults = UserDefaults.standard
    
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
    
    @Published var showUpcomingReminderListName: Bool = {
        return defaults.bool(forKey: PreferencesKeys.showUpcomingReminderListName)
    }() {
        didSet {
            UserPreferences.defaults.set(
                showUpcomingReminderListName,
                forKey: PreferencesKeys.showUpcomingReminderListName
            )
        }
    }
    
    @Published var showRemindersWithDueDateOnTop: Bool = {
        return defaults.boolWithDefaultValueTrue(forKey: PreferencesKeys.showRemindersWithDueDateOnTop)
    }() {
        didSet {
            UserPreferences.defaults.set(
                showRemindersWithDueDateOnTop,
                forKey: PreferencesKeys.showRemindersWithDueDateOnTop
            )
        }
    }
    
    @Published var sortRemindersByPriority: Bool = {
        return defaults.boolWithDefaultValueTrue(forKey: PreferencesKeys.sortRemindersByPriority)
    }() {
        didSet {
            UserPreferences.defaults.set(sortRemindersByPriority, forKey: PreferencesKeys.sortRemindersByPriority)
        }
    }
    
    @Published var showExternalLinksInReminderItem: Bool = {
        return defaults.bool(forKey: PreferencesKeys.showExternalLinksInReminderItem)
    }() {
        didSet {
            UserPreferences.defaults.set(
                showExternalLinksInReminderItem,
                forKey: PreferencesKeys.showExternalLinksInReminderItem
            )
        }
    }
    
    @Published var reminderSortingOrder: RmbSortingOrder = {
        guard let sortingData = defaults.data(forKey: PreferencesKeys.reminderSortingOrder),
              let sorting = try? JSONDecoder().decode(RmbSortingOrder.self, from: sortingData) else {
            return .newestFirst
        }
        return sorting
    }() {
        didSet {
            let sortingData = try? JSONEncoder().encode(reminderSortingOrder)
            UserPreferences.defaults.set(sortingData, forKey: PreferencesKeys.reminderSortingOrder)
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

    @Published var reduceTransparency = NSWorkspace.shared.accessibilityDisplayShouldReduceTransparency

    @Published var preferTransparentBackground: Bool = {
        return defaults.boolWithDefaultValueTrue(forKey: PreferencesKeys.preferTransparentBackground)
    }() {
        didSet {
            UserPreferences.defaults.set(
                preferTransparentBackground,
                forKey: PreferencesKeys.preferTransparentBackground
            )
        }
    }

    var isTransparencyEnabled: Bool {
        preferTransparentBackground && !reduceTransparency
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
    
    @Published var filterMenuBarContentByCalendar: Bool = {
        return defaults.bool(forKey: PreferencesKeys.filterMenuBarContentByCalendar)
    }() {
        didSet {
            UserPreferences.defaults.set(
                filterMenuBarContentByCalendar,
                forKey: PreferencesKeys.filterMenuBarContentByCalendar
            )
        }
    }
    
    @Published var hideMenuBarIconWhenContentIsShown: Bool = {
        return defaults.bool(forKey: PreferencesKeys.hideMenuBarIconWhenContentIsShown)
    }() {
        didSet {
            UserPreferences.defaults.set(
                hideMenuBarIconWhenContentIsShown,
                forKey: PreferencesKeys.hideMenuBarIconWhenContentIsShown
            )
        }
    }

    @Published var menuBarReminderPreviewEnabled: Bool = {
        return defaults.bool(forKey: PreferencesKeys.menuBarReminderPreviewEnabled)
    }() {
        didSet {
            UserPreferences.defaults.set(
                menuBarReminderPreviewEnabled,
                forKey: PreferencesKeys.menuBarReminderPreviewEnabled
            )
        }
    }

    @Published var menuBarReminderPreviewTimeAhead: RmbMenuBarPreviewTimeAhead = {
        guard let data = defaults.data(forKey: PreferencesKeys.menuBarReminderPreviewTimeAhead),
              let timeAhead = try? JSONDecoder().decode(RmbMenuBarPreviewTimeAhead.self, from: data) else {
            return .fifteenMinutes
        }
        return timeAhead
    }() {
        didSet {
            let data = try? JSONEncoder().encode(menuBarReminderPreviewTimeAhead)
            UserPreferences.defaults.set(data, forKey: PreferencesKeys.menuBarReminderPreviewTimeAhead)
        }
    }

    @Published var menuBarReminderPreviewMaxLength: Int = {
        let value = defaults.integer(forKey: PreferencesKeys.menuBarReminderPreviewMaxLength)
        return value > 0 ? value : 10
    }() {
        didSet {
            UserPreferences.defaults.set(
                menuBarReminderPreviewMaxLength,
                forKey: PreferencesKeys.menuBarReminderPreviewMaxLength
            )
        }
    }

    @Published var hideCounterWhenReminderPreviewIsShown: Bool = {
        return defaults.bool(forKey: PreferencesKeys.hideCounterWhenReminderPreviewIsShown)
    }() {
        didSet {
            UserPreferences.defaults.set(
                hideCounterWhenReminderPreviewIsShown,
                forKey: PreferencesKeys.hideCounterWhenReminderPreviewIsShown
            )
        }
    }

    @Published var menuBarReminderPreviewShowTodayReminders: Bool = {
        return defaults.bool(forKey: PreferencesKeys.menuBarReminderPreviewShowTodayReminders)
    }() {
        didSet {
            UserPreferences.defaults.set(
                menuBarReminderPreviewShowTodayReminders,
                forKey: PreferencesKeys.menuBarReminderPreviewShowTodayReminders
            )
        }
    }

    @Published var copyPropertyOptions: [CopyPropertyOption] = {
        guard let data = defaults.data(forKey: PreferencesKeys.copyProperties),
              let decoded = try? JSONDecoder().decode([CopyPropertyOption].self, from: data) else {
            return CopyProperty.defaultOptions
        }
        return CopyProperty.reconciledOptions(from: decoded)
    }() {
        didSet {
            let data = try? JSONEncoder().encode(copyPropertyOptions)
            UserPreferences.defaults.set(data, forKey: PreferencesKeys.copyProperties)
        }
    }

    @Published var copyIncludePropertyNames: Bool = {
        return defaults.bool(forKey: PreferencesKeys.copyIncludePropertyNames)
    }() {
        didSet {
            UserPreferences.defaults.set(copyIncludePropertyNames, forKey: PreferencesKeys.copyIncludePropertyNames)
        }
    }

    @Published var preferredLanguage: String? = {
        return defaults.string(forKey: PreferencesKeys.preferredLanguage)
    }() {
        didSet {
            UserPreferences.defaults.set(preferredLanguage, forKey: PreferencesKeys.preferredLanguage)
        }
    }

    @Published var timeFormatIs24Hour: Bool = {
        guard defaults.object(forKey: PreferencesKeys.timeFormatIs24Hour) != nil else {
            // NOTE: "j" resolves to the locale's preferred hour format; containing "a" indicates 12-hour cycle
            return DateFormatter
                .dateFormat(fromTemplate: "j", options: 0, locale: Locale.current)?
                .contains("a") == false
        }
        return defaults.bool(forKey: PreferencesKeys.timeFormatIs24Hour)
    }() {
        didSet {
            UserPreferences.defaults.set(timeFormatIs24Hour, forKey: PreferencesKeys.timeFormatIs24Hour)
        }
    }

    // This is intentionally not @Published; it is used for persistence and for driving the NSPopover size directly.
    var mainPopoverSize: NSSize {
        get {
            guard let nsSizeData = UserPreferences.defaults.data(forKey: PreferencesKeys.mainPopoverSize),
                  let nsSize = try? JSONDecoder().decode(NSSize.self, from: nsSizeData) else {
                return MainPopoverSizing.defaultSize
            }
            return nsSize
        }
        set {
            let nsSizeData = try? JSONEncoder().encode(newValue)
            UserPreferences.defaults.set(nsSizeData, forKey: PreferencesKeys.mainPopoverSize)
        }
    }
}
