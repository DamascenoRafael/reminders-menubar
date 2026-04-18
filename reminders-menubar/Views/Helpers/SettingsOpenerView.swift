import Combine
import SwiftUI

@available(macOS 14.0, *)
struct SettingsOpenerView: View {
    @Environment(\.openSettings) private var openSettings
    @State private var settingsOpenCancellable: AnyCancellable?
    @State private var settingsCloseCancellable: AnyCancellable?
    @State private var settingsWindow: NSWindow?

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .allowsHitTesting(false)
            .onReceive(NotificationCenter.default.publisher(for: .openSettingsRequest)) { _ in
                Task { @MainActor in
                    await handleOpenSettingsRequest()
                }
            }
    }

    private func handleOpenSettingsRequest() async {
        // If settings window is already open, just bring it to front.
        if let existingWindow = settingsWindow, existingWindow.isVisible {
            NSApp.activate()
            existingWindow.orderFrontRegardless()
            return
        }

        // Clear any stale reference from a previous session.
        settingsWindow = nil

        // Temporarily show dock icon so macOS allows the window to come to front.
        let wasAccessory = NSApp.activationPolicy() == .accessory
        if wasAccessory {
            NSApp.setActivationPolicy(.regular)
            try? await Task.sleep(for: .milliseconds(200))
        }

        // Two parallel detection strategies:
        // 1. Notification-based (fast path): captures the window the instant it becomes key or main.
        // 2. Periodic window scan (fallback): checks NSApp.windows every interval.
        // Calling openSettings() after subscription setup.
        let window: NSWindow? = await withCheckedContinuation { continuation in
            var capturedWindow: NSWindow?

            let windowNotifications = Publishers.Merge(
                NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification),
                NotificationCenter.default.publisher(for: NSWindow.didBecomeMainNotification)
            )
                .compactMap { $0.object as? NSWindow }
                .filter(Self.isSettingsWindow)

            let windowScan = Timer.publish(every: 0.5, on: .main, in: .common)
                .autoconnect()
                .compactMap { _ in NSApp.windows.first(where: Self.isSettingsWindow) }

            settingsOpenCancellable = windowNotifications
                .merge(with: windowScan)
                .first()
                .timeout(.seconds(5), scheduler: DispatchQueue.main)
                .sink(
                    receiveCompletion: { _ in
                        continuation.resume(returning: capturedWindow)
                        settingsOpenCancellable = nil
                    },
                    receiveValue: { window in
                        capturedWindow = window
                    }
                )

            openSettings()
        }

        if let window {
            settingsWindow = window
            NSApp.activate()
            window.makeKeyAndOrderFront(nil)

            // Clean settingsWindow state and restore accessory policy when the settings window closes.
            observeSettingsClose(window, wasAccessory: wasAccessory)
        } else if wasAccessory {
            // Window never appeared; restore accessory policy immediately.
            NSApp.setActivationPolicy(.accessory)
        }
    }

    private static func isSettingsWindow(_ window: NSWindow) -> Bool {
        window.isVisible && window.frame.height > 100
    }

    private func observeSettingsClose(_ window: NSWindow, wasAccessory: Bool) {
        settingsCloseCancellable?.cancel()
        settingsCloseCancellable = NotificationCenter.default
            .publisher(for: NSWindow.willCloseNotification, object: window)
            .first()
            .sink { _ in
                settingsWindow = nil
                if wasAccessory {
                    NSApp.setActivationPolicy(.accessory)
                }
            }
    }
}
