import Cocoa
import SwiftUI

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    let popover = NSPopover()
    let statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let contentView = ContentView()
        let remindersData = RemindersData()

        popover.behavior = .semitransient
        popover.contentSize = NSSize(width: 320, height: 460)
        popover.contentViewController = NSHostingController(rootView: contentView.environmentObject(remindersData))
        
        if let button = statusBarItem.button {
            button.image = NSImage(systemSymbolName: "largecircle.fill.circle", accessibilityDescription: nil)
            button.action = #selector(togglePopover)
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    @objc func togglePopover() {
        guard (RemindersService.instance.hasAuthorization() == .authorized) else {
            RemindersService.instance.requestAccess()
            return
        }
        
        guard let button = statusBarItem.button else {
            return
        }
        
        if popover.isShown {
            popover.performClose(button)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
}
