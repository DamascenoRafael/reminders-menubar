import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        defer {
            NSApp.terminate(self)
        }
        
        guard NSRunningApplication.runningApplications(withBundleIdentifier: Constants.mainAppBundleId).isEmpty else {
            // main app is already running
            return
        }
        
        guard let appUrl = NSWorkspace.shared.urlForApplication(withBundleIdentifier: Constants.mainAppBundleId) else {
            // could not found URL for the main app
            return
        }
        
        let group = DispatchGroup()
        group.enter()
        NSWorkspace.shared.openApplication(
            at: appUrl,
            configuration: NSWorkspace.OpenConfiguration(),
            completionHandler: { _, _ in
                group.leave()
            }
        )
        
        _ = group.wait(timeout: .distantFuture)
    }
}
