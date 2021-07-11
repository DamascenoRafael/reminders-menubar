import Foundation

struct AppConstants {
    static let currentVersion: String = {
        guard let bundleVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            return "-"
        }
        
        return "v\(bundleVersion)"
    }()
    
    static let appName = "Reminders Menu Bar"
    static let mainBundleId = "br.com.damascenorafael.reminders-menu-bar"
    static let launcherBundleId = "br.com.damascenorafael.RemindersLauncher"
}

struct GithubConstants {
    static let repository = "DamascenoRafael/reminders-menubar"
    static let repositoryPage = "https://github.com/\(repository)"
    static let latestReleasePage = "\(repositoryPage)/releases/latest"
}

struct ApiGithubConstants {
    static let latestRelease = "https://api.github.com/repos/\(GithubConstants.repository)/releases/latest"
}
