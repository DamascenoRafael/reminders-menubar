import AppKit

@MainActor
final class CopyShortcutCoordinator: ObservableObject {
    private var monitor: Any?
    private var hoveredReminderId: String?
    private var copyAction: (() -> Void)?

    init() {
        installMonitor()
    }

    func setHovered(reminderId: String, copyAction: @escaping () -> Void) {
        hoveredReminderId = reminderId
        self.copyAction = copyAction
    }

    func clearIfCurrent(reminderId: String) {
        guard hoveredReminderId == reminderId else { return }
        hoveredReminderId = nil
        copyAction = nil
    }

    private func installMonitor() {
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard event.modifierFlags.intersection(.deviceIndependentFlagsMask) == .command,
                  event.charactersIgnoringModifiers?.lowercased() == "c" else {
                return event
            }

            let handled = MainActor.assumeIsolated {
                guard let self, self.hoveredReminderId != nil else {
                    return false
                }
                self.copyAction?()
                return true
            }

            return handled ? nil : event
        }
    }

    deinit {
        if let monitor { NSEvent.removeMonitor(monitor) }
    }
}
