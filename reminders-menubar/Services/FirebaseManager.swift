import Foundation
#if canImport(AppKit)
import AppKit
#endif

#if canImport(FirebaseCore)
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
// Optional Google Sign-In (SPM: GoogleSignIn)
#if canImport(GoogleSignIn)
import GoogleSignIn
#endif

class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()
    private init() {}

    @Published var isConfigured = false
    @Published var currentUser: User? = nil
    var db: Firestore? = nil

    func configureIfNeeded() {
        guard !isConfigured else { return }
        FirebaseApp.configure()
        db = Firestore.firestore()
        Auth.auth().addStateDidChangeListener { _, user in
            DispatchQueue.main.async { self.currentUser = user }
        }
        isConfigured = true
    }

    func signIn(withCustomToken token: String) async throws {
        configureIfNeeded()
        _ = try await Auth.auth().signIn(withCustomToken: token)
    }

    func signInAnonymously() async throws {
        configureIfNeeded()
        _ = try await Auth.auth().signInAnonymously()
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }

    #if canImport(GoogleSignIn)
    @MainActor
    func signInWithGoogle(presenting presenter: NSViewController) async throws {
        configureIfNeeded()
        // Prefer new API; fallback to configuration if required
        if let clientID = FirebaseApp.app()?.options.clientID {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        }

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presenter)
        guard let idToken = result.user.idToken?.tokenString else {
            throw NSError(domain: "GoogleAuth", code: -2, userInfo: [NSLocalizedDescriptionKey: "Missing ID token"])
        }
        let accessToken = result.user.accessToken.tokenString
        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
        _ = try await Auth.auth().signIn(with: credential)
    }

    @MainActor
    func googleSignOut() {
        GIDSignIn.sharedInstance.signOut()
    }
    #else
    func signInWithGoogle(presenting presenter: NSViewController) async throws {
        throw NSError(domain: "GoogleSignInMissing", code: -1, userInfo: [NSLocalizedDescriptionKey: "GoogleSignIn SDK not available"])
    }
    func googleSignOut() { }
    #endif
}

#else

// Fallback stubs when Firebase SDK is not present
class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()
    private init() {}

    @Published var isConfigured = false
    @Published var currentUser: Any? = nil

    func configureIfNeeded() { }
    func signIn(withCustomToken token: String) async throws { throw NSError(domain: "FirebaseMissing", code: -1, userInfo: [NSLocalizedDescriptionKey: "Firebase SDK not available"]) }
    func signInAnonymously() async throws { throw NSError(domain: "FirebaseMissing", code: -1, userInfo: [NSLocalizedDescriptionKey: "Firebase SDK not available"]) }
    func signOut() throws { }

    // Provide stubs so UI compiles even without GoogleSignIn/Firebase
    @MainActor
    func signInWithGoogle(presenting presenter: NSViewController) async throws {
        throw NSError(domain: "FirebaseMissing", code: -1, userInfo: [NSLocalizedDescriptionKey: "Google Sign-In not available"])
    }

    @MainActor
    func googleSignOut() { }
}

#endif
