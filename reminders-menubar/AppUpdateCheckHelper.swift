import SwiftUI

@MainActor
class AppUpdateCheckHelper: ObservableObject {
    static let shared = AppUpdateCheckHelper()

    @Published private(set) var latestRelease: Release?
    @Published private(set) var isOutdated = false

    private let currentRelease = Release(version: AppConstants.currentVersion)
    private let activityScheduler = NSBackgroundActivityScheduler(
        identifier: AppConstants.mainBundleId + ".updatecheck"
    )

    private init() {
        configureScheduler()
        Task {
            await checkLatestRelease()
        }
    }

    deinit {
        activityScheduler.invalidate()
    }

    private func configureScheduler() {
        activityScheduler.repeats = true
        activityScheduler.interval = 10 * 60 * 60 // 10 hours

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

                await self.checkLatestRelease()
                completion(.finished)
            }
        }
    }

    private func checkLatestRelease() async {
        do {
            let release = try await GithubService.getLatestRelease()
            self.latestRelease = release
            self.isOutdated = self.currentRelease < release
        } catch {
            print("Error getting latest release from github:", error.localizedDescription)
        }
    }
}
