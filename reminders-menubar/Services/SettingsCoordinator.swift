import SwiftUI

class SettingsCoordinator: ObservableObject {
    static let shared = SettingsCoordinator()

    @Published var selectedTab: SettingsTab = .general

    private init() {
        // This prevents others from using the default '()' initializer for this class.
    }
}
