import Cocoa
import SwiftUI

@MainActor
final class FilterPanelController: ObservableObject {
    static let shared = FilterPanelController()

    private init() {
        // This prevents others from using the default '()' initializer for this class.
    }

    private var panel: NSPanel?
    private var submenuPanel: NSPanel?
    private weak var anchorView: NSView?

    private var eventMonitors: [Any] = []
    private var closeObservers: [NSObjectProtocol] = []

    @Published private(set) var isVisible = false

    func toggle(relativeTo anchorView: NSView, contentView: some View) {
        if isVisible {
            close()
        } else {
            show(relativeTo: anchorView, contentView: contentView)
        }
    }

    private func show(relativeTo anchorView: NSView, contentView: some View) {
        close()

        self.anchorView = anchorView

        let hostingView = NSHostingView(rootView: contentView)
        let panelSize = hostingView.fittingSize
        hostingView.setFrameSize(panelSize)

        let panel = Self.makePanel(hostingView: hostingView, size: panelSize)
        let anchorRect = anchorView.window?.convertToScreen(
            anchorView.convert(anchorView.bounds, to: nil)
        ) ?? .zero
        let panelOrigin = Self.clampedOrigin(
            panelSize: panelSize,
            anchorRect: anchorRect,
            screen: anchorView.window?.screen
        )
        panel.setFrameOrigin(panelOrigin)
        panel.orderFrontRegardless()

        self.panel = panel
        isVisible = true

        startEventMonitors()
        observePopoverClose()
    }

    private func close() {
        closeSubmenu()
        if let panel {
            panel.orderOut(nil)
        }
        panel = nil
        isVisible = false
        stopEventMonitors()
        stopPopoverCloseObserver()
    }

    // MARK: - Submenu

    private var submenuCloseWork: DispatchWorkItem?

    func showSubmenu(contentView: some View) {
        cancelSubmenuClose()
        closeSubmenu()

        guard let panel else { return }

        let hostingView = NSHostingView(rootView: contentView)
        let submenuSize = hostingView.fittingSize
        hostingView.setFrameSize(submenuSize)

        let submenu = Self.makePanel(hostingView: hostingView, size: submenuSize)
        let submenuOrigin = Self.clampedSubmenuOrigin(
            submenuSize: submenuSize,
            parentFrame: panel.frame,
            screen: panel.screen
        )
        submenu.setFrameOrigin(submenuOrigin)

        panel.addChildWindow(submenu, ordered: .above)
        self.submenuPanel = submenu
    }

    private func closeSubmenu() {
        if let submenuPanel {
            submenuPanel.parent?.removeChildWindow(submenuPanel)
            submenuPanel.orderOut(nil)
        }
        submenuPanel = nil
    }

    func scheduleSubmenuClose() {
        cancelSubmenuClose()
        let work = DispatchWorkItem { [weak self] in
            MainActor.assumeIsolated {
                guard let self else { return }
                let mouseLocation = NSEvent.mouseLocation
                if let submenuPanel = self.submenuPanel, submenuPanel.frame.contains(mouseLocation) {
                    return
                }
                self.closeSubmenu()
            }
        }
        submenuCloseWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: work)
    }

    func cancelSubmenuClose() {
        submenuCloseWork?.cancel()
        submenuCloseWork = nil
    }

    // MARK: - Panel Factory

    private static func makePanel(hostingView: NSView, size: NSSize) -> NSPanel {
        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.nonactivatingPanel],
            backing: .buffered,
            defer: true
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .popUpMenu
        panel.isMovable = false

        panel.contentView = hostingView
        return panel
    }

    // MARK: - Screen Bounds Clamping

    private static func clampedOrigin(panelSize: NSSize, anchorRect: NSRect, screen: NSScreen?) -> NSPoint {
        let screenFrame = screen?.visibleFrame ?? NSScreen.main?.visibleFrame ?? .zero
        let spacing: CGFloat = 1

        let originX = anchorRect.minX
            .constrainedTo(min: screenFrame.minX, max: screenFrame.maxX - panelSize.width)

        let belowAnchor = anchorRect.minY - panelSize.height - spacing
        let aboveAnchor = anchorRect.maxY + spacing
        let originY = (belowAnchor >= screenFrame.minY ? belowAnchor : aboveAnchor)
            .constrainedTo(min: screenFrame.minY, max: screenFrame.maxY - panelSize.height)

        return NSPoint(x: originX, y: originY)
    }

    private static func clampedSubmenuOrigin(submenuSize: NSSize, parentFrame: NSRect, screen: NSScreen?) -> NSPoint {
        let screenFrame = screen?.visibleFrame ?? NSScreen.main?.visibleFrame ?? .zero
        let spacing: CGFloat = 1

        let rightOfParent = parentFrame.maxX + spacing
        let leftOfParent = parentFrame.minX - submenuSize.width - spacing
        let originX = (rightOfParent + submenuSize.width <= screenFrame.maxX ? rightOfParent : leftOfParent)
            .constrainedTo(min: screenFrame.minX, max: screenFrame.maxX - submenuSize.width)

        let originY = (parentFrame.maxY - submenuSize.height)
            .constrainedTo(min: screenFrame.minY, max: screenFrame.maxY - submenuSize.height)

        return NSPoint(x: originX, y: originY)
    }

    // MARK: - Event Monitors

    private var anchorScreenRect: NSRect {
        guard let anchorView, let window = anchorView.window else { return .zero }
        return window.convertToScreen(anchorView.convert(anchorView.bounds, to: nil))
    }

    private func isPointInsideAnyPanel(_ point: NSPoint) -> Bool {
        panel?.frame.contains(point) == true || submenuPanel?.frame.contains(point) == true
    }

    private func startEventMonitors() {
        stopEventMonitors()

        let clickMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] event in
            guard let self else { return event }
            let mouseLocation = NSEvent.mouseLocation
            if anchorScreenRect.contains(mouseLocation) {
                // Click is on the toggle button — let toggle() handle it
                return event
            }
            if !isPointInsideAnyPanel(mouseLocation) {
                close()
            }
            return event
        }

        let keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, event.keyCode == RmbKeyCode.escape else { return event }
            close()
            return nil
        }

        eventMonitors = [clickMonitor, keyMonitor].compactMap { $0 }
    }

    private func stopEventMonitors() {
        eventMonitors.forEach { NSEvent.removeMonitor($0) }
        eventMonitors.removeAll()
    }

    // MARK: - Popover Close Observer

    private func observePopoverClose() {
        stopPopoverCloseObserver()

        closeObservers = [
            NotificationCenter.default.addObserver(
                forName: NSPopover.didCloseNotification,
                object: AppDelegate.shared.popover,
                queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated {
                    self?.close()
                }
            },
            NotificationCenter.default.addObserver(
                forName: NSApplication.didResignActiveNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated {
                    self?.close()
                }
            }
        ]
    }

    private func stopPopoverCloseObserver() {
        closeObservers.forEach { NotificationCenter.default.removeObserver($0) }
        closeObservers.removeAll()
    }
}
