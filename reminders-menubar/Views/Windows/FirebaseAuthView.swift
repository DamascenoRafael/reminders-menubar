import SwiftUI

struct FirebaseAuthView: View {
    @ObservedObject var fb = FirebaseManager.shared
    @State private var customToken: String = ""
    @State private var message: String = ""
    @State private var busy: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Firebase Authentication").font(.title2).fontWeight(.semibold)

            if fb.currentUser != nil {
                Text("Signed in").font(.footnote).foregroundColor(.secondary)
            }

            GroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Sign in with your Google account to enable direct Firestore access.")
                        .font(.footnote)
                    HStack(spacing: 8) {
                        Button("Sign in with Google") { Task { await signInGoogle() } }
                        Button("Sign Out") { signOutAll() }
                    }
                }
            } label: {
                Text("Google Sign-In")
            }

            GroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Paste a Firebase Custom Token (issued by BOB)").font(.footnote)
                    SecureField("custom token", text: $customToken).textFieldStyle(.roundedBorder)
                    HStack {
                        Button("Sign In with Token") { Task { await signInWithToken() } }
                        Button("Anonymous Sign In") { Task { await signInAnon() } }
                        Button("Sign Out") { signOutAll() }
                        Spacer()
                        Button("Close") { closeWindow() }
                    }
                }
            } label: {
                Text("Custom Token (optional)")
            }

            if busy { ProgressView().controlSize(.small) }
            if !message.isEmpty { Text(message).font(.footnote).foregroundColor(.secondary) }
        }
        .padding(16)
        .frame(width: 560)
        .onAppear { fb.configureIfNeeded() }
    }

    private func signOutAll() {
        do {
            fb.googleSignOut()
            try fb.signOut()
            message = "Signed out"
        } catch { message = "Sign out error: \(error.localizedDescription)" }
    }

    private func signInAnon() async {
        busy = true; defer { busy = false }
        do { try await fb.signInAnonymously(); message = "Signed in anonymously" } catch { message = error.localizedDescription }
    }

    private func signInWithToken() async {
        busy = true; defer { busy = false }
        do { try await fb.signIn(withCustomToken: customToken); message = "Signed in" } catch { message = error.localizedDescription }
    }

    private func signInGoogle() async {
        busy = true; defer { busy = false }
        guard let presenter = NSApp.keyWindow?.contentViewController else {
            message = "No active window to present Google Sign-In"; return
        }
        do {
            try await fb.signInWithGoogle(presenting: presenter)
            message = "Signed in with Google"
        } catch { message = error.localizedDescription }
    }

    private func closeWindow() { NSApp.keyWindow?.close() }

    static func showWindow() {
        let vc = NSHostingController(rootView: FirebaseAuthView())
        let wc = NSWindowController(window: NSWindow(contentViewController: vc))
        if let w = wc.window {
            w.title = "Firebase Auth"
            w.titleVisibility = .hidden
            w.titlebarAppearsTransparent = true
            w.animationBehavior = .alertPanel
            w.styleMask = [.titled, .closable]
        }
        wc.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

struct FirebaseAuthView_Previews: PreviewProvider {
    static var previews: some View { FirebaseAuthView() }
}
