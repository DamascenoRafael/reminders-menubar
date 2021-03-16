import EventKit
import ServiceManagement

private struct PreferencesKeys {
    static let calendarIdentifiersFilter = "calendarIdentifiersFilter"
    static let calendarIdentifierForSaving = "calendarIdentifierForSaving"
    static let showUncompletedOnly = "showUncompletedOnly"
    static let backgroundIsTransparent = "backgroundIsTransparent"
    static let showUpcomingReminders = "showUpcomingReminders"
    static let upcomingRemindersInterval = "upcomingRemindersInterval"
}

class UserPreferences: ObservableObject {
    static let instance = UserPreferences()
    
    private init() {
        // This prevents others from using the default '()' initializer for this class.
    }
    
    private let defaults = UserDefaults.standard
        
    var calendarIdentifiersFilter: [String] {
        get {
            guard let identifiers = defaults.stringArray(forKey: PreferencesKeys.calendarIdentifiersFilter) else {
                return []
            }
            
            return identifiers
        }
        
        set {
            defaults.set(newValue, forKey: PreferencesKeys.calendarIdentifiersFilter)
        }
    }
    
    var calendarForSaving: EKCalendar {
        get {
            guard let identifier = defaults.string(forKey: PreferencesKeys.calendarIdentifierForSaving),
                  let calendar = RemindersService.instance.getCalendar(withIdentifier: identifier) else {
                let defaultCalendar = RemindersService.instance.getDefaultCalendar()
                self.calendarForSaving = defaultCalendar
                return defaultCalendar
            }
            
            return calendar
        }
        
        set {
            let identifier = newValue.calendarIdentifier
            defaults.set(identifier, forKey: PreferencesKeys.calendarIdentifierForSaving)
        }
    }
    
    var showUncompletedOnly: Bool {
        get {
            guard defaults.object(forKey: PreferencesKeys.showUncompletedOnly) != nil else {
                return true
            }
            
            return defaults.bool(forKey: PreferencesKeys.showUncompletedOnly)
        }
        
        set {
            defaults.set(newValue, forKey: PreferencesKeys.showUncompletedOnly)
        }
    }
    
    var upcomingRemindersInterval: ReminderInterval {
        get {
            guard let intervalData = defaults.data(forKey: PreferencesKeys.upcomingRemindersInterval),
                  let interval = try? JSONDecoder().decode(ReminderInterval.self, from: intervalData) else {
                return .today
            }
            return interval
        }
        
        set {
            let intervalData = try? JSONEncoder().encode(newValue)
            defaults.set(intervalData, forKey: PreferencesKeys.upcomingRemindersInterval)
        }
    }
    
    @Published var showUpcomingReminders: Bool = {
        guard UserDefaults.standard.object(forKey: PreferencesKeys.showUpcomingReminders) != nil else {
            return true
        }
        return UserDefaults.standard.bool(forKey: PreferencesKeys.showUpcomingReminders)
    }() {
        didSet {
            defaults.set(showUpcomingReminders, forKey: PreferencesKeys.showUpcomingReminders)
        }
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
    
    @Published var backgroundIsTransparent: Bool = {
        guard UserDefaults.standard.object(forKey: PreferencesKeys.backgroundIsTransparent) != nil else {
            return true
        }
        return UserDefaults.standard.bool(forKey: PreferencesKeys.backgroundIsTransparent)
    }() {
        didSet {
            defaults.set(backgroundIsTransparent, forKey: PreferencesKeys.backgroundIsTransparent)
        }
    }
}
