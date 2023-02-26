import SwiftUI
import KeyboardShortcuts

struct KeyboardShortcutView: View {
    @ObservedObject var keyboardShortcutService = KeyboardShortcutService.shared
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Spacer()
                
                VStack(alignment: .leading, spacing: 16) {
                    Toggle(rmbLocalized(.keyboardShortcutEnableOpenShortcutOption, arguments: AppConstants.appName),
                           isOn: $keyboardShortcutService.isOpenRemindersMenuBarEnabled)
                    
                    Group {
                        HStack {
                            KeyboardShortcuts.Recorder(for: .openRemindersMenuBar)
                            
                            Button(action: {
                                KeyboardShortcutService.shared.reset(.openRemindersMenuBar)
                                // Remove focus from ShortcutRecorder
                                removeFocusFromFirstResponder()
                            }) {
                                Text(rmbLocalized(.keyboardShortcutRestoreDefaultButton))
                                    .padding(.horizontal, 4)
                                    .frame(minWidth: 113)
                            }
                        }
                    }
                    .padding(.leading, 20)
                    .disabled(!keyboardShortcutService.isOpenRemindersMenuBarEnabled)
                }
                
                Spacer()
            }
        }
        .padding(.top, 16)
        .padding(.bottom, 24)
        .padding(.horizontal, 32)
        .frame(width: 520, height: 180)
        .onAppear {
            // Remove focus from ShortcutRecorder
            removeFocusFromFirstResponder()
        }
    }
    
    static func showWindow() {
        let viewController = NSHostingController(rootView: KeyboardShortcutView())
        let windowController = NSWindowController(window: NSWindow(contentViewController: viewController))
        
        if let window = windowController.window {
            window.title = rmbLocalized(.keyboardShortcutWindowTitle)
            window.titlebarAppearsTransparent = true
            window.animationBehavior = .alertPanel
            window.styleMask = [.titled, .closable]
        }
        
        windowController.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

struct KeyboardShortcutView_Previews: PreviewProvider {
    static var previews: some View {
        KeyboardShortcutView()
    }
}
