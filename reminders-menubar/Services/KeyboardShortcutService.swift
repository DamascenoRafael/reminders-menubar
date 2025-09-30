import SwiftUI
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let openRemindersMenuBar = Self("OpenRemindersMenuBar", default: .init(.r, modifiers: [.command, .option]))
    static let runBobSync = Self("RunBobSync", default: .init(.s, modifiers: [.command, .shift]))
}

private enum ShortcutsKeys {
    static let isOpenRemindersMenuBarEnabled = "isOpenRemindersMenuBarEnabled"
    static let isRunBobSyncEnabled = "isRunBobSyncEnabled"
}

@MainActor
class KeyboardShortcutService: ObservableObject {
    static let shared = KeyboardShortcutService()
    
    private init() {
        // This prevents others from using the default '()' initializer for this class.
    }
    
    private static let defaults = UserDefaults.standard
    
    @Published var isOpenRemindersMenuBarEnabled: Bool = {
        return defaults.bool(forKey: ShortcutsKeys.isOpenRemindersMenuBarEnabled)
    }() {
        didSet {
            KeyboardShortcutService.defaults.set(
                isOpenRemindersMenuBarEnabled,
                forKey: ShortcutsKeys.isOpenRemindersMenuBarEnabled
            )
            setEnabled(isOpenRemindersMenuBarEnabled, for: .openRemindersMenuBar)
        }
    }

    @Published var isRunBobSyncEnabled: Bool = {
        if let stored = defaults.object(forKey: ShortcutsKeys.isRunBobSyncEnabled) as? Bool {
            return stored
        }
        return true
    }() {
        didSet {
            KeyboardShortcutService.defaults.set(
                isRunBobSyncEnabled,
                forKey: ShortcutsKeys.isRunBobSyncEnabled
            )
            setEnabled(isRunBobSyncEnabled, for: .runBobSync)
        }
    }
    
    func activeShortcut(for shortcutName: KeyboardShortcuts.Name) -> String {
        guard isEnabled(shortcutName) else {
            return ""
        }
        
        return KeyboardShortcuts.Shortcut(name: shortcutName)?.description ?? ""
    }
    
    func action(for shortcutName: KeyboardShortcuts.Name, action: @escaping () -> Void) {
        KeyboardShortcuts.onKeyDown(for: shortcutName) {
            action()
        }
        let isEnabled = isEnabled(shortcutName)
        setEnabled(isEnabled, for: shortcutName)
    }
    
    func reset(_ shortcutName: KeyboardShortcuts.Name) {
        KeyboardShortcuts.reset(shortcutName)
    }
    
    private func isEnabled(_ shortcutName: KeyboardShortcuts.Name) -> Bool {
        switch shortcutName {
        case .openRemindersMenuBar:
            return isOpenRemindersMenuBarEnabled
        case .runBobSync:
            return isRunBobSyncEnabled
        default:
            return false
        }
    }
    
    private func setEnabled(_ isEnabled: Bool, for shortcutName: KeyboardShortcuts.Name) {
        if isEnabled {
            KeyboardShortcuts.enable(shortcutName)
        } else {
            KeyboardShortcuts.disable(shortcutName)
        }
    }
}
