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

class AppDelegate: NSObject, NSApplicationDelegate {
    
    static private(set) var shared: AppDelegate!
    
    private var didCloseCancellationToken: AnyCancellable?
    private var didCloseEventDate = Date.distantPast

    let popover = NSPopover()
    lazy var statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
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
        configureAppColorScheme()
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
    
    func configureAppColorScheme() {
        let colorScheme = UserPreferences.shared.rmbColorScheme
        NSApplication.shared.appearance = colorScheme.nsAppearance
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
    
    func updateMenuBarTodayCount(to todayCount: Int) {
        let buttonTitle = todayCount > 0 ? String(todayCount) : ""
        statusBarItem.button?.title = buttonTitle
    }
    
    func changeBehaviorToDismissIfNeeded() {
        popover.behavior = .transient
    }
    
    private func changeBehaviorToKeepVisible() {
        popover.behavior = .applicationDefined
    }
    
    func changeBehaviorBasedOnModal(isShowing: Bool) {
        if isShowing {
            changeBehaviorToKeepVisible()
        } else {
            changeBehaviorToDismissIfNeeded()
        }
    }

    private func requestAuthorization() {
        let authorization = RemindersService.shared.authorizationStatus()
        if authorization == .restricted || authorization == .denied {
            presentNoAuthorizationAlert()
        } else {
            RemindersService.shared.requestAccess()
        }
    }
    
    private func presentNoAuthorizationAlert() {
        let alert = NSAlert()
        alert.messageText = rmbLocalized(.appNoRemindersAccessAlertMessage, arguments: AppConstants.appName)
        alert.informativeText = rmbLocalized(.appNoRemindersAccessAlertDescription,
                                             arguments: AppConstants.appName,
                                             AppConstants.appName)
        alert.addButton(withTitle: rmbLocalized(.okButton))
        alert.addButton(withTitle: rmbLocalized(.openSystemPreferencesButton))
        alert.addButton(withTitle: rmbLocalized(.appQuitButton)).hasDestructiveAction = true
        
        NSApp.activate(ignoringOtherApps: true)
        let modalResponse = alert.runModal()
        if modalResponse == .alertSecondButtonReturn,
           let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Reminders") {
            NSWorkspace.shared.open(url)
        } else if modalResponse == .alertThirdButtonReturn {
            NSApp.terminate(self)
        }
    }

    @objc private func togglePopover() {
        guard RemindersService.shared.authorizationStatus() == .authorized else {
            requestAuthorization()
            return
        }
        
        guard popover.behavior != .applicationDefined,
              let button = statusBarItem.button else {
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
