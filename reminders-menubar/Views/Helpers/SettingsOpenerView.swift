import Combine
import SwiftUI

@available(macOS 14.0, *)
struct SettingsOpenerView: View {
    @Environment(\.openSettings) private var openSettings
    @State private var settingsCloseCancellable: AnyCancellable?

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .allowsHitTesting(false)
            .onReceive(NotificationCenter.default.publisher(for: .openSettingsRequest)) { _ in
                Task { @MainActor in
                    // Temporarily show dock icon so macOS allows the window to come to front.
                    let wasAccessory = NSApp.activationPolicy() == .accessory
                    if wasAccessory {
                        NSApp.setActivationPolicy(.regular)
                        try? await Task.sleep(for: .milliseconds(200))
                    }

                    NSApp.activate()
                    openSettings()

                    // Give the settings window time to appear, then bring it to front.
                    try? await Task.sleep(for: .milliseconds(600))
                    if let settingsWindow = getSettingsWindow() {
                        settingsWindow.orderFrontRegardless()

                        // Restore accessory policy when the settings window closes.
                        if wasAccessory {
                            observeSettingsClose(settingsWindow)
                        }
                    } else if wasAccessory {
                        // Window never appeared; restore accessory policy immediately.
                        NSApp.setActivationPolicy(.accessory)
                    }
                }
            }
    }

    private func getSettingsWindow() -> NSWindow? {
        if let settingsWindow = NSApp.keyWindow {
            return settingsWindow
        }
        return NSApp.orderedWindows.first { $0.isVisible }
    }

    private func observeSettingsClose(_ window: NSWindow) {
        settingsCloseCancellable?.cancel()
        settingsCloseCancellable = NotificationCenter.default
            .publisher(for: NSWindow.willCloseNotification, object: window)
            .first()
            .delay(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .sink { _ in
                NSApp.setActivationPolicy(.accessory)
            }
    }
}
