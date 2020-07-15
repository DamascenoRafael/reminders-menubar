import Cocoa
import SwiftUI

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var popover: NSPopover!
    var statusBarItem: NSStatusItem!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let contentView = ContentView()

        let popover = NSPopover()
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: contentView)
        self.popover = popover
        
        self.statusBarItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.squareLength)
        
        if let button = self.statusBarItem.button {
            // button.image = NSImage(named: "reminders")
            button.title = "🔖"
            button.action = #selector(togglePopover)
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    @objc func togglePopover() {
        guard let button = self.statusBarItem.button else {
            return
        }
        
        if self.popover.isShown {
            self.popover.performClose(button)
        } else {
            self.popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
        }
    }

}

