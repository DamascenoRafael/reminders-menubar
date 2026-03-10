import Cocoa

extension Notification.Name {
    static let openSettingsRequest = Notification.Name("openSettingsRequest")
}

extension NSApplication {
    @MainActor
    func openAppSettings(tab: SettingsTab = .general) {
        SettingsView.initialTab = tab

        if #available(macOS 14.0, *) {
            // Note: Post a notification that the hidden helper view (SettingsOpenerView) will pick up.
            NotificationCenter.default.post(name: .openSettingsRequest, object: nil)
        } else if #available(macOS 13.0, *) {
            sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            activate(ignoringOtherApps: true)
        } else {
            sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
            activate(ignoringOtherApps: true)
        }
    }
}
