import SwiftUI

struct BobSyncSettingsView: View {
    @ObservedObject var prefs = UserPreferences.shared
    @State private var isSyncing = false
    @State private var syncMessage: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("BOB Sync Settings").font(.title3)

            VStack(alignment: .leading, spacing: 8) {
                Text("Base URL")
                TextField("https://bob20250810.web.app", text: $prefs.bobBaseUrl)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("User UID")
                TextField("Enter your BOB user UID", text: $prefs.bobUserUid)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Reminders Secret")
                SecureField("Enter the Reminders secret", text: $prefs.bobRemindersSecret)
                    .textFieldStyle(.roundedBorder)
            }

            HStack {
                Button("Run Sync from BOB → Reminders") {
                    isSyncing = true
                    syncMessage = ""
                    Task {
                        await BobSyncService.shared.syncFromBob()
                        isSyncing = false
                        syncMessage = "Sync complete"
                    }
                }
                .disabled(!BobSyncService.shared.isConfigured || isSyncing)

                if isSyncing { ProgressView().controlSize(.small) }
                Spacer()
                Button("Close") { NSApp.keyWindow?.close() }
            }

            if !syncMessage.isEmpty {
                Text(syncMessage).foregroundColor(.secondary).font(.footnote)
            }
        }
        .padding(16)
        .frame(width: 420)
    }

    static func showWindow() {
        let viewController = NSHostingController(rootView: BobSyncSettingsView())
        let windowController = NSWindowController(window: NSWindow(contentViewController: viewController))

        if let window = windowController.window {
            window.title = "BOB Sync Settings"
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.styleMask = [.titled, .closable]
        }

        windowController.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

struct BobSyncSettingsView_Previews: PreviewProvider {
    static var previews: some View { BobSyncSettingsView() }
}

