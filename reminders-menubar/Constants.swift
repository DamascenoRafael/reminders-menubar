import Foundation

enum AppConstants {
    static let currentVersion: String = {
        guard let bundleVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            return "-"
        }
        
        return "v\(bundleVersion)"
    }()
    
    static let appName = "Reminders MenuBar"
    static let mainBundleId = "br.com.damascenorafael.reminders-menubar"
    static let launcherBundleId = "br.com.damascenorafael.RemindersLauncher"
}

enum GithubConstants {
    static let repository = "DamascenoRafael/reminders-menubar"
    static let repositoryPage = "https://github.com/\(repository)"
    static let latestReleasePage = "\(repositoryPage)/releases/latest"
}

enum ApiGithubConstants {
    static let latestRelease = "https://api.github.com/repos/\(GithubConstants.repository)/releases/latest"
}
