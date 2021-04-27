import Cocoa
import SwiftUI

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    let popover = NSPopover()
    let statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    var contentViewController: NSViewController {
        let contentView = ContentView()
        let remindersData = RemindersData()
        return NSHostingController(rootView: contentView.environmentObject(remindersData))
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        AppUpdateCheckHelper.instance.startBackgroundActivity()
        
        changeBehaviorToDismissIfNeeded()
        configurePopover()
        configureMenuBarButton()
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
        statusBarItem.button?.action = #selector(togglePopover)
    }
    
    func changeBehaviorToDismissIfNeeded() {
        popover.behavior = .transient
    }
    
    func changeBehaviorToKeepVisible() {
        popover.behavior = .applicationDefined
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
        alert.messageText = "Access to Reminders is not enabled for Reminders Menu Bar"
        alert.informativeText = """
            Reminders Menu Bar needs access to your reminders to work properly.
            Grant permission in System Preferences to use Reminders Menu Bar.
            """
        alert.addButton(withTitle: "Ok")
        alert.addButton(withTitle: "Open System Preferences")
        alert.addButton(withTitle: "Quit").hasDestructiveAction = true
        
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
        }
    }
}
