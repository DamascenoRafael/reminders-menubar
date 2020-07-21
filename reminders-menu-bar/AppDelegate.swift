import Cocoa
import SwiftUI

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var popover: NSPopover!
    var statusBarItem: NSStatusItem!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let contentView = ContentView()
        let remindersData = RemindersData()

        let popover = NSPopover()
        popover.behavior = .semitransient
        popover.contentSize = NSSize(width: 320, height: 460)
        popover.contentViewController = NSHostingController(rootView: contentView.environmentObject(remindersData))
        self.popover = popover
        
        self.statusBarItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.squareLength)
        
        if let button = self.statusBarItem.button {
            button.image = NSImage(named: "dot.filled.circle")
            button.image?.size = NSSize(width: 18, height: 18)
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
