import Cocoa
import SwiftUI
import Combine

@main
struct RemindersMenuBar: App {
    // swiftlint:disable:next weak_delegate
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
    
    private var didCloseCancellationToken: AnyCancellable?
    private var didCloseEventDate = Date.distantPast
    
    private var sharedAuthorizationErrorMessage: String?

    let popover = NSPopover()
    lazy var statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    @MainActor
    var contentViewController: NSViewController {
        let contentView = ContentView()
        let remindersData = RemindersData()
        return NSHostingController(rootView: contentView.environmentObject(remindersData))
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        AppDelegate.shared = self
        
        AppUpdateCheckHelper.shared.startBackgroundActivity()
        
        changeBehaviorToDismissIfNeeded()
        configurePopover()
        configureMenuBarButton()
        configureKeyboardShortcut()
        configureDidCloseNotification()
    }
    
    private func configurePopover() {
        popover.contentSize = NSSize(width: 340, height: 460)
        popover.animates = false
        
        if RemindersService.shared.authorizationStatus() == .authorized {
            popover.contentViewController = contentViewController
        }
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
        statusBarItem.button?.action = #selector(togglePopover)
    }
    
    private func configureKeyboardShortcut() {
        KeyboardShortcutService.shared.action(for: .openRemindersMenuBar) { [weak self] in
            self?.togglePopover()
        }
    }
    
    private func configureDidCloseNotification() {
        // NOTE: There is an issue where if the menu bar button is clicked on its top part to close the popover
        // there will be a didClose event and then togglePopover will be called (reopening the popover).
        // didCloseEventDate is saved to figure out if the event is recent and the popover should not be reopened.
        didCloseCancellationToken = NotificationCenter.default
            .publisher(for: NSPopover.didCloseNotification, object: popover)
            .sink { [weak self] _ in
                self?.didCloseEventDate = Date()
            }
    }
    
    private func changeBehaviorToDismissIfNeeded() {
        popover.behavior = .transient
    }

    @objc private func togglePopover() {
        guard RemindersService.shared.authorizationStatus() == .authorized else {
            requestAuthorization()
            return
        }
        
        guard let button = statusBarItem.button else {
            return
        }
        
        if popover.contentViewController == nil {
            popover.contentViewController = contentViewController
        }
        
        if popover.isShown || didCloseEventDate.elapsedTimeInterval < 0.01 {
            didCloseEventDate = .distantPast
            popover.performClose(button)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
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
        alert.informativeText = rmbLocalized(.appNoRemindersAccessAlertDescription,
                                             arguments: AppConstants.appName,
                                             AppConstants.appName)
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
