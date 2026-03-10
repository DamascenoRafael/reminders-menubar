import Cocoa

@MainActor
final class RightClickMenuHelper: NSObject {
    static let shared = RightClickMenuHelper()

    private override init() {
        super.init()
    }

    // MARK: - Build Menu

    func buildRightClickMenu() -> NSMenu {
        let menu = NSMenu()

        let launchAtLoginItem = NSMenuItem(
            title: rmbLocalized(.launchAtLoginOptionButton),
            action: #selector(toggleLaunchAtLogin),
            keyEquivalent: ""
        )
        launchAtLoginItem.target = self
        launchAtLoginItem.state = UserPreferences.shared.launchAtLoginIsEnabled ? .on : .off
        menu.addItem(launchAtLoginItem)

        menu.addItem(.separator())

        let reloadItem = NSMenuItem(
            title: rmbLocalized(.reloadRemindersDataButton),
            action: #selector(reloadData),
            keyEquivalent: ""
        )
        reloadItem.target = self
        reloadItem.image = NSImage(systemSymbolName: "arrow.clockwise", accessibilityDescription: nil)
        menu.addItem(reloadItem)

        menu.addItem(.separator())

        let settingsItem = NSMenuItem(
            title: rmbLocalized(.settingsButtonHelp),
            action: #selector(openSettingsAction),
            keyEquivalent: ""
        )
        settingsItem.target = self
        settingsItem.image = NSImage(systemSymbolName: "gearshape", accessibilityDescription: nil)
        menu.addItem(settingsItem)

        let aboutItem = NSMenuItem(
            title: rmbLocalized(.appAboutButton),
            action: #selector(openAbout),
            keyEquivalent: ""
        )
        aboutItem.target = self
        aboutItem.image = NSImage(systemSymbolName: "info.circle", accessibilityDescription: nil)
        menu.addItem(aboutItem)

        let quitItem = NSMenuItem(
            title: rmbLocalized(.appQuitButton),
            action: #selector(quitApp),
            keyEquivalent: ""
        )
        quitItem.target = self
        quitItem.image = NSImage(systemSymbolName: "xmark.rectangle", accessibilityDescription: nil)
        menu.addItem(quitItem)

        return menu
    }

    // MARK: - Actions

    @objc private func toggleLaunchAtLogin() {
        UserPreferences.shared.launchAtLoginIsEnabled.toggle()
    }

    @objc private func reloadData() {
        UserPreferences.shared.remindersMenuBarOpeningEvent.toggle()
    }

    @objc private func openSettingsAction() {
        NSApp.openAppSettings()
    }

    @objc private func openAbout() {
        NSApp.openAppSettings(tab: .about)
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
