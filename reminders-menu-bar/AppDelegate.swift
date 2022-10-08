import Cocoa
import SwiftUI

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
    
    static private(set) var instance: AppDelegate!

    let popover = NSPopover()
    lazy var statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    var contentViewController: NSViewController {
        let contentView = ContentView()
        let remindersData = RemindersData()
        return NSHostingController(rootView: contentView.environmentObject(remindersData))
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        AppDelegate.instance = self
        
        AppUpdateCheckHelper.instance.startBackgroundActivity()
        
        changeBehaviorToDismissIfNeeded()
        configurePopover()
        configureMenuBarButton()
        configureKeyboardShortcut()
    }
    
    private func configurePopover() {
        popover.contentSize = NSSize(width: 340, height: 460)
        popover.animates = false
        
        if RemindersService.instance.authorizationStatus() == .authorized {
            popover.contentViewController = contentViewController
        }
    }
    
    private func configureMenuBarButton() {
        statusBarItem.button?.image = NSImage(systemSymbolName: "list.bullet", accessibilityDescription: nil)
        statusBarItem.button?.imagePosition = .imageLeading
        statusBarItem.button?.action = #selector(togglePopover)
    }
    
    private func configureKeyboardShortcut() {
        KeyboardShortcutService.instance.action(for: .openRemindersMenuBar) { [weak self] in
            self?.togglePopover()
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
        let authorization = RemindersService.instance.authorizationStatus()
        if authorization == .restricted || authorization == .denied {
            presentNoAuthorizationAlert()
        } else {
            RemindersService.instance.requestAccess()
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
        guard RemindersService.instance.authorizationStatus() == .authorized else {
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
        
        if popover.isShown {
            popover.performClose(button)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            UserPreferences.instance.remindersMenuBarOpeningEvent.toggle()
        }
    }
}
