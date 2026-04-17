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

        menu.addItem(makeMenuItem(
            title: rmbLocalized(.launchAtLoginOption),
            action: #selector(toggleLaunchAtLogin),
            state: UserPreferences.shared.launchAtLoginIsEnabled ? .on : .off
        ))

        menu.addItem(.separator())

        menu.addItem(makeMenuItem(
            title: rmbLocalized(.reloadRemindersDataButton),
            action: #selector(reloadData),
            systemSymbolName: "arrow.clockwise"
        ))

        menu.addItem(.separator())

        if UpdateController.shared.isOutdated {
            menu.addItem(makeMenuItem(
                title: rmbLocalized(.updateAvailableNoticeButton),
                action: #selector(showUpdate),
                systemSymbolName: "arrow.down.circle"
            ))
        } else {
            menu.addItem(makeMenuItem(
                title: rmbLocalized(.checkForUpdatesButton),
                action: #selector(checkForUpdates),
                systemSymbolName: "arrow.down.circle"
            ))
        }

        menu.addItem(makeMenuItem(
            title: rmbLocalized(.appSettingsButton),
            action: #selector(openSettingsAction),
            systemSymbolName: "gearshape"
        ))

        menu.addItem(makeMenuItem(
            title: rmbLocalized(.appAboutButton),
            action: #selector(openAbout),
            systemSymbolName: "info.circle"
        ))

        menu.addItem(makeMenuItem(
            title: rmbLocalized(.appQuitButton),
            action: #selector(quitApp),
            systemSymbolName: "xmark.rectangle"
        ))

        return menu
    }

    // MARK: - Helpers

    private func makeMenuItem(
        title: String,
        action: Selector,
        systemSymbolName: String? = nil,
        state: NSControl.StateValue? = nil
    ) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        if let systemSymbolName {
            item.image = NSImage(systemSymbolName: systemSymbolName, accessibilityDescription: nil)
        }
        if let state {
            item.state = state
        }
        return item
    }

    // MARK: - Actions

    @objc private func toggleLaunchAtLogin() {
        UserPreferences.shared.launchAtLoginIsEnabled.toggle()
    }

    @objc private func reloadData() {
        NotificationCenter.default.post(name: .remindersDataShouldUpdate, object: nil)
    }

    @objc private func openSettingsAction() {
        NSApp.openAppSettings()
    }

    @objc private func checkForUpdates() {
        UpdateController.shared.checkForUpdates()
    }

    @objc private func showUpdate() {
        UpdateController.shared.showUpdate()
    }

    @objc private func openAbout() {
        NSApp.openAppSettings(tab: .about)
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
