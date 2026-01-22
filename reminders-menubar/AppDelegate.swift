import Cocoa
import SwiftUI

@main
struct RemindersMenuBar: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
        .commands {
            AppCommands()
        }
    }
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    static private(set) var shared: AppDelegate!

    private var sharedAuthorizationErrorMessage: String?

    private var panel: NSPanel?
    lazy var statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    
    var contentViewController: NSViewController {
        let contentView = ContentView()
        let remindersData = RemindersData()
        return NSHostingController(rootView: contentView.environmentObject(remindersData))
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        AppDelegate.shared = self

        AppUpdateCheckHelper.shared.startBackgroundActivity()

        configurePanel()
        configureMenuBarButton()
        configureKeyboardShortcut()
    }

    private func configurePanel() {
        let defaultSize = NSSize(width: 340, height: 460)
        let minSize = NSSize(width: 280, height: 300)

        let contentRect = UserPreferences.shared.windowFrame ?? NSRect(origin: .zero, size: defaultSize)

        let panel = NSPanel(
            contentRect: contentRect,
            styleMask: [.borderless, .resizable, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.isMovableByWindowBackground = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isReleasedWhenClosed = false
        panel.minSize = minSize
        panel.hasShadow = true
        panel.backgroundColor = .clear
        panel.alphaValue = 0.9

        if RemindersService.shared.authorizationStatus() == .authorized {
            panel.contentViewController = contentViewController
        }

        if UserPreferences.shared.windowFrame == nil {
            panel.center()
        }

        configureMouseTracking(for: panel)

        self.panel = panel
    }

    private func configureMouseTracking(for panel: NSPanel) {
        guard let contentView = panel.contentView else { return }

        let trackingArea = NSTrackingArea(
            rect: contentView.bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        contentView.addTrackingArea(trackingArea)
    }

    override func mouseEntered(with event: NSEvent) {
        panel?.animator().alphaValue = 1.0
    }

    override func mouseExited(with event: NSEvent) {
        panel?.animator().alphaValue = 0.9
    }
    
    func updateMenuBarTodayCount(to todayCount: Int) {
        let buttonTitle = todayCount > 0 ? String(todayCount) : ""
        statusBarItem.button?.title = buttonTitle
    }
    
    func loadMenuBarIcon() {
        let menuBarIcon = UserPreferences.shared.reminderMenuBarIcon
        statusBarItem.button?.image = menuBarIcon.image
    }
    
    private func configureMenuBarButton() {
        loadMenuBarIcon()
        statusBarItem.button?.imagePosition = .imageLeading
        statusBarItem.button?.action = #selector(togglePanel)
    }
    
    private func configureKeyboardShortcut() {
        KeyboardShortcutService.shared.action(for: .openRemindersMenuBar) { [weak self] in
            self?.togglePanel()
        }
    }

    @objc private func togglePanel() {
        guard RemindersService.shared.authorizationStatus() == .authorized else {
            requestAuthorization()
            return
        }

        guard let panel = panel else {
            return
        }

        if panel.contentViewController == nil {
            panel.contentViewController = contentViewController
        }

        if panel.isVisible {
            UserPreferences.shared.windowFrame = panel.frame
            panel.orderOut(nil)
        } else {
            panel.makeKeyAndOrderFront(nil)
            UserPreferences.shared.remindersMenuBarOpeningEvent.toggle()
        }
    }
}

// - MARK: Authorization functions

extension AppDelegate: NSAlertDelegate {
    private func requestAuthorization() {
        RemindersService.shared.requestAccess { [weak self] granted, errorMessage in
            if granted {
                return
            }
                
            print("Access to reminders not granted:", errorMessage ?? "no error description")
            DispatchQueue.main.async {
                self?.sharedAuthorizationErrorMessage = errorMessage
                self?.presentNoAuthorizationAlert()
            }
        }
    }
    
    private func presentNoAuthorizationAlert() {
        let alert = NSAlert()
        alert.messageText = rmbLocalized(.appNoRemindersAccessAlertMessage, arguments: AppConstants.appName)
        let reasonDescription = rmbLocalized(
            .appNoRemindersAccessAlertReasonDescription,
            arguments: AppConstants.appName
        )
        let actionDescription = rmbLocalized(
            .appNoRemindersAccessAlertActionDescription,
            arguments: AppConstants.appName
        )
        alert.informativeText = "\(reasonDescription)\n\(actionDescription)"
        if sharedAuthorizationErrorMessage != nil {
            alert.delegate = self
            alert.showsHelp = true
        }
        
        alert.addButton(withTitle: rmbLocalized(.okButton))
        alert.addButton(withTitle: rmbLocalized(.openSystemPreferencesButton))
        alert.addButton(withTitle: rmbLocalized(.appQuitButton)).hasDestructiveAction = true
        
        NSApp.activate(ignoringOtherApps: true)
        let modalResponse = alert.runModal()
        switch modalResponse {
        case .alertSecondButtonReturn:
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Reminders") {
                NSWorkspace.shared.open(url)
            }
        case .alertThirdButtonReturn:
            NSApp.terminate(self)
        default:
            sharedAuthorizationErrorMessage = nil
        }
    }
    
    internal func alertShowHelp(_ alert: NSAlert) -> Bool {
        let helpAlert = NSAlert()
        let errorDescription = sharedAuthorizationErrorMessage ?? "no error description"
        helpAlert.icon = NSImage(systemSymbolName: "calendar.badge.exclamationmark", accessibilityDescription: nil)
        helpAlert.messageText = rmbLocalized(.appNoRemindersAccessAlertMessage, arguments: AppConstants.appName)
        helpAlert.informativeText = "Authorization error: \(errorDescription)"
        helpAlert.runModal()
        
        return true
    }
}
