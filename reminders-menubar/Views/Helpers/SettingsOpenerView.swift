import Combine
import SwiftUI

@available(macOS 14.0, *)
struct SettingsOpenerView: View {
    @Environment(\.openSettings) private var openSettings
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

        // Temporarily show dock icon so macOS allows the window to come to front.
        let wasAccessory = NSApp.activationPolicy() == .accessory
        if wasAccessory {
            NSApp.setActivationPolicy(.regular)
            try? await Task.sleep(for: .milliseconds(200))
        }

        NSApp.activate()
        openSettings()

        // Wait for the settings window to appear, then bring it to front.
        if let window = await pollForSettingsWindow(timeout: .milliseconds(2_000)) {
            settingsWindow = window
            window.orderFrontRegardless()

            // Clean settingsWindow state and restore accessory policy when the settings window closes.
            observeSettingsClose(window, wasAccessory: wasAccessory)
        } else if wasAccessory {
            // Window never appeared; restore accessory policy immediately.
            NSApp.setActivationPolicy(.accessory)
        }
    }

    /// Polls until a new visible window appears or the timeout expires.
    private func pollForSettingsWindow(timeout: Duration) async -> NSWindow? {
        let deadline = ContinuousClock.now + timeout
        let interval = Duration.milliseconds(50)
        while ContinuousClock.now < deadline {
            if let window = NSApp.keyWindow, window.isVisible {
                return window
            }
            try? await Task.sleep(for: interval)
        }
        return NSApp.keyWindow
    }

    private func observeSettingsClose(_ window: NSWindow, wasAccessory: Bool) {
        settingsCloseCancellable?.cancel()
        settingsCloseCancellable = NotificationCenter.default
            .publisher(for: NSWindow.willCloseNotification, object: window)
            .first()
            .delay(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .sink { _ in
                settingsWindow = nil
                if wasAccessory {
                    NSApp.setActivationPolicy(.accessory)
                }
            }
    }
}
