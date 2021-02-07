import EventKit
import ServiceManagement

private struct PreferencesKeys {
    static let calendarIdentifiersFilter = "calendarIdentifiersFilter"
    static let calendarIdentifierForSaving = "calendarIdentifierForSaving"
    static let showUncompletedOnly = "showUncompletedOnly"
}

class UserPreferences {
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
            
            let filteredIdentifiers = identifiers.filter({ RemindersService.instance.isValid(calendarIdentifier: $0) })
            self.calendarIdentifiersFilter = filteredIdentifiers
            return filteredIdentifiers
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
}
