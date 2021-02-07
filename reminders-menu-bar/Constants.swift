import Foundation

struct AppConstants {
    static let currentVersion: String = {
        guard let bundleVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            return "-"
        }
        
        return "v\(bundleVersion)"
    }()
    
    static let mainBundleId = "br.com.damascenorafael.reminders-menu-bar"
    static let launcherBundleId = "br.com.damascenorafael.RemindersLauncher"
}

struct GithubConstants {
    static let repository = "DamascenoRafael/reminders-menubar"
    static let pageUrlString = "https://github.com/\(repository)"
}
