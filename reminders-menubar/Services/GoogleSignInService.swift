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

        guard let presentingWindow = NSApp.keyWindow ?? NSApp.windows.first else {
            throw NSError(domain: "GoogleSignIn", code: 1, userInfo: [NSLocalizedDescriptionKey: "No window to present sign-in"])
        }

        if let clientID = FirebaseApp.app()?.options.clientID {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        }
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingWindow)

        guard let idToken = result.user.idToken?.tokenString else {
            throw NSError(domain: "GoogleSignIn", code: 2, userInfo: [NSLocalizedDescriptionKey: "Missing Google ID token"])
        }
        let accessToken = result.user.accessToken.tokenString

        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
        _ = try await Auth.auth().signIn(with: credential)
    }

    func signOut() {
        try? Auth.auth().signOut()
        GIDSignIn.sharedInstance.signOut()
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
