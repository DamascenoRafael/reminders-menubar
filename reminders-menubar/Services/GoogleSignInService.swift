import Foundation

#if canImport(GoogleSignIn) && canImport(FirebaseAuth) && canImport(FirebaseCore) && canImport(AppKit)
import GoogleSignIn
import FirebaseAuth
import FirebaseCore
import AppKit

@MainActor
class GoogleSignInService: ObservableObject {
    static let shared = GoogleSignInService()
    private init() {}

    func signIn() async throws {
        FirebaseManager.shared.configureIfNeeded()

        var tempWindow: NSWindow? = nil
        var presentingWindow = NSApp.keyWindow ?? NSApp.windows.first
        if presentingWindow == nil {
            // Menubar apps can have no key window; create a tiny, nearly invisible window to satisfy API
            let w = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 10, height: 10),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            w.isOpaque = false
            w.alphaValue = 0.01
            w.level = .floating
            w.orderFrontRegardless()
            NSApp.activate(ignoringOtherApps: true)
            presentingWindow = w
            tempWindow = w
        }

        if let clientID = FirebaseApp.app()?.options.clientID {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        }
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingWindow!)

        guard let idToken = result.user.idToken?.tokenString else {
            throw NSError(domain: "GoogleSignIn", code: 2, userInfo: [NSLocalizedDescriptionKey: "Missing Google ID token"])
        }
        let accessToken = result.user.accessToken.tokenString

        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
        defer { tempWindow?.close() }
        _ = try await Auth.auth().signIn(with: credential)
        LogService.shared.log(.info, .auth, "Google sign-in success for uid=\(Auth.auth().currentUser?.uid ?? "unknown")")
    }

    func signOut() {
        try? Auth.auth().signOut()
        GIDSignIn.sharedInstance.signOut()
        LogService.shared.log(.info, .auth, "Signed out")
    }

    func handle(_ url: URL) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
}
#else
@MainActor
class GoogleSignInService: ObservableObject {
    static let shared = GoogleSignInService()
    private init() {}
    func signIn() async throws { throw NSError(domain: "GoogleSignIn", code: -1, userInfo: [NSLocalizedDescriptionKey: "GoogleSignIn not available"]) }
    func signOut() {}
    func handle(_ url: URL) -> Bool { return false }
}
#endif
