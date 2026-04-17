import Foundation

enum AppConstants {
    static let bundleVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String

    static let displayVersion: String = {
        guard let bundleVersion else {
            return "-"
        }
        
        return "v\(bundleVersion)"
    }()
    
    static let appName = "Reminders MenuBar"
    static let mainBundleId = "br.com.damascenorafael.reminders-menubar"
    static let launcherBundleId = "br.com.damascenorafael.reminders-menubar-launcher"
}

enum GithubConstants {
    static let repository = "DamascenoRafael/reminders-menubar"
    static let repositoryPage = "https://github.com/\(repository)"
    static let latestReleasePage = "\(repositoryPage)/releases/latest"
}

#if APPSTORE
enum AppStoreConstants {
    static let appId = "PLACEHOLDER_APP_ID"
    static let appPage = "macappstore://apps.apple.com/app/id\(appId)"
    static let versionCheckUrl = "https://itunes.apple.com/lookup?bundleId=\(AppConstants.mainBundleId)"
}
#endif
