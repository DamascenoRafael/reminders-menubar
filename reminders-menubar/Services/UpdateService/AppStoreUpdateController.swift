#if APPSTORE
import SwiftUI

@MainActor
final class AppStoreUpdateController: ObservableObject {
    static let shared = AppStoreUpdateController()

    @Published private(set) var isOutdated = false

    private let urlSession = URLSession(configuration: .ephemeral)
    private let activityScheduler: NSBackgroundActivityScheduler

    private init() {
        activityScheduler = NSBackgroundActivityScheduler(
            identifier: AppConstants.mainBundleId + ".appstore.updatecheck"
        )
        configureScheduler()
        Task {
            await fetchLatestVersion()
        }
    }

    deinit {
        activityScheduler.invalidate()
    }

    private func configureScheduler() {
        activityScheduler.repeats = true
        activityScheduler.interval = 24 * 60 * 60 // 24 hours

        activityScheduler.schedule { [weak self] completion in
            Task { @MainActor in
                guard let self else {
                    completion(.finished)
                    return
                }

                if self.activityScheduler.shouldDefer {
                    completion(.deferred)
                    return
                }

                await self.fetchLatestVersion()
                completion(.finished)
            }
        }
    }

    @discardableResult
    private func fetchLatestVersion() async -> Bool {
        guard let versionCheckUrl = URL(string: AppStoreConstants.versionCheckUrl) else {
            return false
        }

        do {
            let request = URLRequest(url: versionCheckUrl, cachePolicy: .reloadIgnoringLocalCacheData)
            let (data, _) = try await urlSession.data(for: request)
            let response = try JSONDecoder().decode(AppStoreVersionResponse.self, from: data)

            guard let storeVersion = response.results.first?.version,
                  let currentVersion = AppConstants.bundleVersion else {
                return false
            }

            let outdated = currentVersion.compare(storeVersion, options: .numeric) == .orderedAscending
            self.isOutdated = outdated
            return outdated
        } catch {
            print("Error checking App Store version:", error.localizedDescription)
            return false
        }
    }

    func openAppStorePage() {
        if let url = URL(string: AppStoreConstants.appPage) {
            NSWorkspace.shared.open(url)
        }
    }

    func checkForUpdates() {
        Task {
            let updateAvailable = await fetchLatestVersion()

            if updateAvailable {
                let alert = NSAlert()
                alert.messageText = rmbLocalized(.updateAvailableAlertTitle)
                alert.informativeText = rmbLocalized(.updateAvailableAlertMessage)
                alert.alertStyle = .informational
                alert.addButton(withTitle: rmbLocalized(.openAppStoreButton))
                alert.addButton(withTitle: rmbLocalized(.updateLaterButton))

                let response = alert.runModal()
                if response == .alertFirstButtonReturn {
                    openAppStorePage()
                }
            } else {
                let alert = NSAlert()
                alert.messageText = rmbLocalized(.upToDateAlertTitle)
                alert.informativeText = rmbLocalized(.upToDateAlertMessage, arguments: AppConstants.appName)
                alert.alertStyle = .informational
                alert.addButton(withTitle: rmbLocalized(.okButton))
                alert.runModal()
            }
        }
    }
}

// MARK: - App Store Version Check

private struct AppStoreVersionResponse: Decodable {
    let resultCount: Int
    let results: [AppStoreVersionResult]
}

private struct AppStoreVersionResult: Decodable {
    let version: String
}
#endif
