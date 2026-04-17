#if !APPSTORE
import SwiftUI
import Sparkle

@MainActor
final class SparkleUpdateController: NSObject, ObservableObject, SPUUpdaterDelegate, SPUStandardUserDriverDelegate {
    static let shared = SparkleUpdateController()

    private var sparkleUpdater: SPUStandardUpdaterController!
    private var didTemporarilyBecomeRegular = false

    @Published var isOutdated = false

    private override init() {
        super.init()

        sparkleUpdater = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: self,
            userDriverDelegate: self
        )
    }

    func checkForUpdates() {
        if NSApp.activationPolicy() == .accessory {
            didTemporarilyBecomeRegular = true
            NSApp.setActivationPolicy(.regular)
        }
        NSApp.activate(ignoringOtherApps: true)
        sparkleUpdater.checkForUpdates(nil)
    }

    // MARK: - SPUUpdaterDelegate

    nonisolated func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem) {
        Task { @MainActor in
            self.isOutdated = true
        }
    }

    nonisolated func updaterDidNotFindUpdate(_ updater: SPUUpdater) {
        Task { @MainActor in
            self.isOutdated = false
        }
    }

    // MARK: - SPUStandardUserDriverDelegate

    nonisolated func standardUserDriverWillFinishUpdateSession() {
        Task { @MainActor in
            if self.didTemporarilyBecomeRegular {
                self.didTemporarilyBecomeRegular = false
                NSApp.setActivationPolicy(.accessory)
            }
        }
    }
}
#endif
