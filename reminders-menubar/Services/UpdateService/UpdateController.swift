import SwiftUI

@MainActor
class UpdateController: ObservableObject {
    static let shared = UpdateController()

    @Published var isOutdated = false

    #if APPSTORE
    private let appStoreController = AppStoreUpdateController.shared
    #else
    private let sparkleController = SparkleUpdateController.shared
    #endif

    private init() {
        #if APPSTORE
        appStoreController.$isOutdated
            .assign(to: &$isOutdated)
        #else
        sparkleController.$isOutdated
            .assign(to: &$isOutdated)
        #endif
    }

    // User-initiated check for updates.
    func checkForUpdates() {
        #if APPSTORE
        appStoreController.checkForUpdates()
        #else
        sparkleController.checkForUpdates()
        #endif
    }

    // Show the update to the user.
    func showUpdate() {
        #if APPSTORE
        appStoreController.openAppStorePage()
        #else
        sparkleController.checkForUpdates()
        #endif
    }
}
