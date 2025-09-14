import Foundation

#if canImport(FirebaseCore)
import FirebaseCore
import FirebaseAuth

class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()
    private init() {}

    @Published var isSignedIn: Bool = false
    @Published var displayName: String? = nil
    @Published var email: String? = nil
    @Published var uid: String? = nil

    private var authListener: AuthStateDidChangeListenerHandle?

    func configureIfNeeded() {
        // Configure Firebase if plist exists
        if FirebaseApp.app() == nil {
            let hasPlist = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil
            if hasPlist { FirebaseApp.configure() }
        }
        // Ensure listener installed and state published
        if authListener == nil {
            authListener = Auth.auth().addStateDidChangeListener { [weak self] _, _ in
                self?.refreshUser()
            }
        }
        refreshUser()
    }

    var currentUid: String? { uid }

    func refreshUser() {
        let user = Auth.auth().currentUser
        isSignedIn = (user != nil)
        uid = user?.uid
        displayName = user?.displayName ?? user?.providerData.first?.displayName
        email = user?.email ?? user?.providerData.first?.email
        if let u = uid, !u.isEmpty, UserPreferences.shared.bobUserUid != u {
            UserPreferences.shared.bobUserUid = u
        }
    }

    static var isAvailable: Bool { true }
}
#else
class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()
    private init() {}
    func configureIfNeeded() {}
    @Published var isSignedIn: Bool = false
    @Published var displayName: String? = nil
    @Published var email: String? = nil
    @Published var uid: String? = nil
    var currentUid: String? { uid }
    static var isAvailable: Bool { false }
}
#endif
