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
        changeBehaviorToDismissIfNeeded()
        popover.contentSize = NSSize(width: 340, height: 460)
        popover.animates = false

        if let button = statusBarItem.button {
            button.image = NSImage(systemSymbolName: "largecircle.fill.circle", accessibilityDescription: nil)
            button.action = #selector(togglePopover)
        }
    }
    
    func changeBehaviorToDismissIfNeeded() {
        popover.behavior = .transient
    }
    
    func changeBehaviorToKeepVisible() {
        popover.behavior = .applicationDefined
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    @objc func togglePopover() {
        guard RemindersService.instance.hasAuthorization() == .authorized else {
            RemindersService.instance.requestAccess()
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
