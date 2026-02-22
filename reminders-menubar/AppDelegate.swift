import Cocoa
import SwiftUI
import Combine

@main
struct RemindersMenuBar: App {
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

    private enum MainPopoverSizing {
        static let defaultWidth: CGFloat = 340
        static let defaultHeight: CGFloat = 460
        static let minWidth: CGFloat = 300
        static let minHeight: CGFloat = 320
        static let absoluteMaxWidth: CGFloat = 900
        static let absoluteMaxHeight: CGFloat = 1_000
        static let maxWidthPadding: CGFloat = 80
        static let maxHeightPadding: CGFloat = 120
    }
    
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
        
        changeBehaviorToDismissIfNeeded()
        configurePopover()
        configureMenuBarButton()
        configureKeyboardShortcut()
        configureDidCloseNotification()
        configureDidShowNotification()
    }
    
    private func configurePopover() {
        let width = clampedMainPopoverWidth(UserPreferences.shared.mainPopoverWidth)
        let height = clampedMainPopoverHeight(UserPreferences.shared.mainPopoverHeight)
        popover.contentSize = NSSize(width: width, height: height)
        popover.animates = false
        
        if RemindersService.shared.authorizationStatus() == .authorized {
            popover.contentViewController = contentViewController
        }
    }

    func setMainPopoverSize(width: CGFloat, height: CGFloat, persist: Bool) {
        let clampedWidth = clampedMainPopoverWidth(width)
        let clampedHeight = clampedMainPopoverHeight(height)
        popover.contentSize = NSSize(width: clampedWidth, height: clampedHeight)

        if persist {
            UserPreferences.shared.mainPopoverWidth = clampedWidth
            UserPreferences.shared.mainPopoverHeight = clampedHeight
        }
    }

    func setMainPopoverHeight(_ height: CGFloat, persist: Bool) {
        setMainPopoverSize(width: popover.contentSize.width, height: height, persist: persist)
    }

    private func mainScreenVisibleFrame() -> CGRect {
        if let screen = statusBarItem.button?.window?.screen {
            return screen.visibleFrame
        }
        return NSScreen.main?.visibleFrame ?? CGRect(x: 0, y: 0, width: 1_440, height: 900)
    }

    private func clampedMainPopoverWidth(_ width: CGFloat) -> CGFloat {
        let screenWidth = mainScreenVisibleFrame().width
        let maxWidth = min(
            MainPopoverSizing.absoluteMaxWidth,
            max(MainPopoverSizing.minWidth, screenWidth - MainPopoverSizing.maxWidthPadding)
        )
        return min(max(width, MainPopoverSizing.minWidth), maxWidth)
    }

    private func clampedMainPopoverHeight(_ height: CGFloat) -> CGFloat {
        let screenHeight = mainScreenVisibleFrame().height
        let maxHeight = min(
            MainPopoverSizing.absoluteMaxHeight,
            max(MainPopoverSizing.minHeight, screenHeight - MainPopoverSizing.maxHeightPadding)
        )
        return min(max(height, MainPopoverSizing.minHeight), maxHeight)
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

    func applicationWillTerminate(_ notification: Notification) {
        stopOutsideClickMonitors()
    }

    private func startOutsideClickMonitors() {
        stopOutsideClickMonitors()

        globalOutsideClickMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]
        ) { [weak self] event in
            Task { @MainActor in
                self?.handlePossibleOutsideClick(event: event)
            }
        }

        localOutsideClickMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]
        ) { [weak self] event in
            Task { @MainActor in
                self?.handlePossibleOutsideClick(event: event)
            }
            return event
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

    private func handlePossibleOutsideClick(event: NSEvent) {
        guard popover.isShown else { return }

        // Use current mouse location so global monitors (which often lack window info) still work reliably.
        let mouseLocation = NSEvent.mouseLocation

        if isMouseLocationInsideStatusItemButton(mouseLocation) {
            // Let the normal status item button action handle toggling.
            return
        }

        if let popoverWindow = popover.contentViewController?.view.window,
           popoverWindow.frame.contains(mouseLocation) {
            return
        }

        // If the click is inside any of our app's windows (menus, child popovers, etc.), do nothing.
        if let window = NSApp.window(withWindowNumber: event.windowNumber),
           window.frame.contains(mouseLocation) {
            return
        }

        popover.performClose(nil)
    }

    private func isMouseLocationInsideStatusItemButton(_ mouseLocation: NSPoint) -> Bool {
        guard let button = statusBarItem.button, let window = button.window else { return false }

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
