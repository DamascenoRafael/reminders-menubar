import SwiftUI
#if canImport(FirebaseAuth)
import FirebaseAuth
#endif

struct FirebaseAuthView: View {
    @ObservedObject var fb = FirebaseManager.shared
    @State private var customToken: String = ""
    @State private var message: String = ""
    @State private var busy: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Bob Authentication").font(.title2).fontWeight(.semibold)

            if let user = fb.currentUser {
                let email = user.email ?? "anonymous"
                Text("Signed in as \(email) (uid: \(user.uid))").font(.footnote).foregroundColor(.secondary)
            } else {
                Text("Not signed in").font(.footnote).foregroundColor(.secondary)
            }

            GroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Sign in with your Google account to enable Bob sync and Firestore access.")
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
                    Text("Paste a Bob custom token (issued by your workspace)").font(.footnote)
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
                Text("Bob Token (optional)")
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
        } catch { message = describe(error, context: "Sign out") }
    }

    private func signInAnon() async {
        busy = true; defer { busy = false }
        do { try await fb.signInAnonymously(); message = "Signed in anonymously" }
        catch { message = describe(error, context: "Anonymous sign-in") }
    }

    private func signInWithToken() async {
        busy = true; defer { busy = false }
        let token = customToken.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !token.isEmpty else {
            message = "Custom token is empty."; return
        }
        do {
            try await fb.signIn(withCustomToken: token)
            await MainActor.run { customToken = "" }
            message = "Signed in"
        }
        catch { message = describe(error, context: "Custom token sign-in") }
    }

    private func signInGoogle() async {
        busy = true; defer { busy = false }
        guard let window = NSApp.keyWindow else {
            message = "No active window to present Google Sign-In"; return
        }
        do {
            try await fb.signInWithGoogle(presenting: window)
            message = "Signed in with Google"
        } catch { message = describe(error, context: "Google sign-in") }
    }

    private func closeWindow() { NSApp.keyWindow?.close() }

    private func describe(_ error: Error, context: String) -> String {
        let nsError = error as NSError
        var parts: [String] = []
        parts.append("\(context) failed: \(nsError.localizedDescription)")
        if let reason = nsError.userInfo[NSLocalizedFailureReasonErrorKey] as? String, !reason.isEmpty {
            parts.append(reason)
        }
#if canImport(FirebaseAuth)
        if nsError.domain == AuthErrorDomain,
           AuthErrorCode.Code(rawValue: nsError.code) == .keychainError {
            parts.append("macOS blocked keychain access. Ensure the app has the keychain entitlement or run a signed build.")
        }
#endif
        if let underlying = nsError.userInfo[NSUnderlyingErrorKey] as? NSError {
            parts.append(underlying.localizedDescription)
        }
        let payload = parts.joined(separator: " — ")
        SyncLogService.shared.logEvent(tag: "auth", level: "ERROR", message: "\(context): \(payload)")
        return payload
    }

    static func showWindow() {
        let viewController = NSHostingController(rootView: FirebaseAuthView())
        let windowController = NSWindowController(window: NSWindow(contentViewController: viewController))
        if let window = windowController.window {
            window.title = "Bob Auth"
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.animationBehavior = .alertPanel
            window.styleMask = [.titled, .closable]
        }
        windowController.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

struct FirebaseAuthView_Previews: PreviewProvider {
    static var previews: some View { FirebaseAuthView() }
}
