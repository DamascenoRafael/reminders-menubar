import SwiftUI

struct AppCommands: Commands {
    @CommandsBuilder var body: some Commands {
        CommandMenu("Edit") {
            // NOTE: macOS 12.0 already has the below shortcuts for TextField.
            // Shortcuts only need to be registered for versions earlier than macOS 12.0.
            if #unavailable(macOS 12.0) {
                Button("Select All") {
                    NSApp.sendAction(#selector(NSText.selectAll(_:)), to: nil, from: nil)
                }
                .keyboardShortcut(KeyEquivalent("a"), modifiers: .command)
                
                Button("Cut") {
                    NSApp.sendAction(#selector(NSText.cut(_:)), to: nil, from: nil)
                }
                .keyboardShortcut(KeyEquivalent("x"), modifiers: .command)
                
                Button("Copy") {
                    NSApp.sendAction(#selector(NSText.copy(_:)), to: nil, from: nil)
                }
                .keyboardShortcut(KeyEquivalent("c"), modifiers: .command)
                
                Button("Paste") {
                    NSApp.sendAction(#selector(NSText.paste(_:)), to: nil, from: nil)
                }
                .keyboardShortcut(KeyEquivalent("v"), modifiers: .command)
                
                Button("Undo") {
                    NSApp.sendAction(Selector(("undo:")), to: nil, from: nil)
                }
                .keyboardShortcut(KeyEquivalent("z"), modifiers: .command)
                
                Button("Redo") {
                    NSApp.sendAction(Selector(("redo:")), to: nil, from: nil)
                }
                .keyboardShortcut(KeyEquivalent("z"), modifiers: [.command, .shift])
            }
        }
    }
}
