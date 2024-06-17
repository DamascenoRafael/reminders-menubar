import SwiftUI

struct AppCommands: Commands {
    @CommandsBuilder var body: some Commands {
        CommandMenu(Text(verbatim: "Edit")) {
            // NOTE: macOS 13.0 already has the below shortcuts for TextField.
            // Shortcuts only need to be registered for versions earlier than macOS 13.0.
            if #unavailable(macOS 13.0) {
                Button {
                    NSApp.sendAction(#selector(NSText.selectAll(_:)), to: nil, from: nil)
                } label: {
                    Text(verbatim: "Select All")
                }
                .keyboardShortcut(KeyEquivalent("a"), modifiers: .command)
                
                Button {
                    NSApp.sendAction(#selector(NSText.cut(_:)), to: nil, from: nil)
                } label: {
                    Text(verbatim: "Cut")
                }
                .keyboardShortcut(KeyEquivalent("x"), modifiers: .command)
                
                Button {
                    NSApp.sendAction(#selector(NSText.copy(_:)), to: nil, from: nil)
                } label: {
                    Text(verbatim: "Copy")
                }
                .keyboardShortcut(KeyEquivalent("c"), modifiers: .command)
                
                Button {
                    NSApp.sendAction(#selector(NSText.paste(_:)), to: nil, from: nil)
                } label: {
                    Text(verbatim: "Paste")
                }
                .keyboardShortcut(KeyEquivalent("v"), modifiers: .command)
                
                Button {
                    NSApp.sendAction(Selector(("undo:")), to: nil, from: nil)
                } label: {
                    Text(verbatim: "Undo")
                }
                .keyboardShortcut(KeyEquivalent("z"), modifiers: .command)
                
                Button {
                    NSApp.sendAction(Selector(("redo:")), to: nil, from: nil)
                } label: {
                    Text(verbatim: "Redo")
                }
                .keyboardShortcut(KeyEquivalent("z"), modifiers: [.command, .shift])
            }
        }
    }
}
