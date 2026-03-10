import Cocoa
import SwiftUI
import Combine

@main
struct RemindersMenuBar: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        if #available(macOS 14.0, *) {
            Window(String(""), id: "SettingsOpener") {
                SettingsOpenerView()
            }
            .windowResizability(.contentSize)
            .windowStyle(.hiddenTitleBar)
            .defaultSize(width: 0, height: 0)
        }

        Settings {
            SettingsView()
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
    private var didShowCancellationToken: AnyCancellable?
    private var didCloseEventDate = Date.distantPast

    private var globalOutsideClickMonitor: Any?
    private var localOutsideClickMonitor: Any?
    
    private var sharedAuthorizationErrorMessage: String?

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

        configurePopover()
        configureMenuBarButton()
        configureKeyboardShortcut()
        configureDidCloseNotification()
        configureDidShowNotification()
    }

    func applicationWillTerminate(_ notification: Notification) {
        stopOutsideClickMonitors()
    }

    private func configurePopover() {
        setMainPopoverSize(size: UserPreferences.shared.mainPopoverSize, persist: true)
        popover.animates = false
        popover.behavior = .transient

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
        statusBarItem.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
        statusBarItem.button?.action = #selector(handleStatusBarButtonAction)
    }
    
    private func configureKeyboardShortcut() {
        KeyboardShortcutService.shared.action(for: .openRemindersMenuBar) { [weak self] in
            self?.togglePopover()
        }
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

    // - MARK: Popover sizing

    func setMainPopoverSize(size: NSSize, persist: Bool) {
        let clampedSize = clampedMainPopoverSize(size: size)
        popover.contentSize = clampedSize

        if persist {
            UserPreferences.shared.mainPopoverSize = clampedSize
        }
    }

    private func mainScreenVisibleFrame() -> NSRect {
        if let screen = statusBarItem.button?.window?.screen {
            return screen.visibleFrame
        }
        return NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1_440, height: 900)
    }

    private func clampedMainPopoverSize(size: NSSize) -> NSSize {
        let screenSize = mainScreenVisibleFrame()

        let maxWidth = (screenSize.width - MainPopoverSizing.minWidthPadding)
            .constrainedTo(min: MainPopoverSizing.minSize.width, max: MainPopoverSizing.maxSize.width)
        let width = size.width.constrainedTo(min: MainPopoverSizing.minSize.width, max: maxWidth)

        let maxHeight = (screenSize.height - MainPopoverSizing.minHeightPadding)
            .constrainedTo(min: MainPopoverSizing.minSize.height, max: MainPopoverSizing.maxSize.height)
        let height = size.height.constrainedTo(min: MainPopoverSizing.minSize.height, max: maxHeight)

        return NSSize(width: width, height: height)
    }

    // - MARK: Fallback for popover open/close behavior

    private func configureDidCloseNotification() {
        // NOTE: There is an issue where if the menu bar button is clicked on its top part to close the popover
        // there will be a didClose event and then togglePopover will be called (reopening the popover).
        // didCloseEventDate is saved to figure out if the event is recent and the popover should not be reopened.
        didCloseCancellationToken = NotificationCenter.default
            .publisher(for: NSPopover.didCloseNotification, object: popover)
            .sink { [weak self] _ in
                self?.didCloseEventDate = Date()
                self?.stopOutsideClickMonitors()
            }
    }

    private func configureDidShowNotification() {
        // SwiftUI `Menu` inside an NSPopover can occasionally break the system's transient dismissal behavior.
        // Install a fallback outside-click monitor while the popover is visible.
        didShowCancellationToken = NotificationCenter.default
            .publisher(for: NSPopover.didShowNotification, object: popover)
            .sink { [weak self] _ in
                self?.startOutsideClickMonitors()
            }
    }

    private func startOutsideClickMonitors() {
        stopOutsideClickMonitors()

        globalOutsideClickMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]
        ) { [weak self] event in
            MainActor.assumeIsolated {
                if self?.isClickOutsidePopover(event: event) ?? false {
                    self?.popover.performClose(nil)
                }
            }
        }

        localOutsideClickMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]
        ) { [weak self] event in
            // Return nil to swallow the event when dismissing, matching native transient popover behavior.
            let shouldClose = MainActor.assumeIsolated {
                self?.isClickOutsidePopover(event: event) ?? false
            }
            if shouldClose {
                self?.popover.performClose(nil)
            }
            return shouldClose ? nil : event
        }
    }

    private func stopOutsideClickMonitors() {
        if let monitor = globalOutsideClickMonitor {
            NSEvent.removeMonitor(monitor)
            globalOutsideClickMonitor = nil
        }
        if let monitor = localOutsideClickMonitor {
            NSEvent.removeMonitor(monitor)
            localOutsideClickMonitor = nil
        }
    }

    private func isClickOutsidePopover(event: NSEvent) -> Bool {
        guard popover.isShown else { return false }

        let mouseLocation = NSEvent.mouseLocation

        if isMouseInsideStatusBarButton(mouseLocation) {
            return false
        }

        if let popoverWindow = popover.contentViewController?.view.window,
           popoverWindow.frame.contains(mouseLocation) {
            return false
        }

        if let window = NSApp.window(withWindowNumber: event.windowNumber),
           window.frame.contains(mouseLocation) {
            return false
        }

        return true
    }

    private func isMouseInsideStatusBarButton(_ mouseLocation: NSPoint) -> Bool {
        guard let button = statusBarItem.button,
              let window = button.window else {
            return false
        }

        let rectInWindow = button.convert(button.bounds, to: nil)
        let rectOnScreen = window.convertToScreen(rectInWindow)
        return rectOnScreen.contains(mouseLocation)
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
