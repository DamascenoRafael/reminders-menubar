import SwiftUI
import WebKit

struct WebSignInView: View {
    @ObservedObject var prefs = UserPreferences.shared
    @State private var webView: WKWebView? = nil
    @State private var status: String = ""
    @State private var currentUrl: URL? = nil

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Text("Sign in with Google (BOB)").font(.headline)
                Spacer()
                if FirebaseManager.isAvailable {
                    Button("Sign in with Google (native)") {
                        Task {
                            do {
                                try await GoogleSignInService.shared.signIn()
                                if let uid = FirebaseManager.shared.currentUid { prefs.bobUserUid = uid }
                                let name = FirebaseManager.shared.displayName ?? FirebaseManager.shared.email ?? FirebaseManager.shared.currentUid ?? "unknown"
                                status = "Signed in as: \(name)"
                            } catch {
                                status = "Native sign-in failed: \(error.localizedDescription)"
                            }
                        }
                    }
                }
                Button("Open Settings") {
                    if let url = URL(string: prefs.bobBaseUrl + "/#/settings") {
                        webView?.load(URLRequest(url: url))
                    }
                }
                Button("Try Capture UID") {
                    tryCaptureUID()
                }
                Button("Close") {
                    NSApp.keyWindow?.close()
                }
            }
            .padding(8)
            Divider()

            RepresentedWebView(webView: $webView, startURL: URL(string: prefs.bobBaseUrl) ?? URL(string: "https://bob20250810.web.app")!)
                .onReceive(NotificationCenter.default.publisher(for: .WKWebViewURLDidChange)) { note in
                    if let wv = note.object as? WKWebView { currentUrl = wv.url }
                }

            Divider()
            HStack {
                Text(status).font(.footnote).foregroundColor(.secondary)
                Spacer()
                Button("Reload") { webView?.reload() }
            }.padding(8)
        }
        .frame(width: 900, height: 620)
    }

    private func tryCaptureUID() {
        guard let wv = webView else { return }
        // Attempt to read Firebase Auth user from localStorage
        let js = """
        (function(){
          try {
            var keys = Object.keys(localStorage).filter(k=>k.startsWith('firebase:authUser:'));
            if (!keys.length) return JSON.stringify({ ok:false, reason:'no_auth_keys' });
            for (var i=0;i<keys.length;i++){
              var raw = localStorage.getItem(keys[i]);
              if (!raw) continue;
              var obj = JSON.parse(raw);
              if (obj && obj.uid) return JSON.stringify({ ok:true, uid: obj.uid });
            }
            return JSON.stringify({ ok:false, reason:'no_uid' });
          } catch(e) {
            return JSON.stringify({ ok:false, reason:'exception', message: String(e) });
          }
        })();
        """
        wv.evaluateJavaScript(js) { result, error in
            if let error = error {
                status = "Capture failed: \(error.localizedDescription)"
                return
            }
            guard let str = result as? String, let data = str.data(using: .utf8) else {
                status = "Unexpected capture result"
                return
            }
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let ok = json["ok"] as? Bool, ok, let uid = json["uid"] as? String { 
                    prefs.bobUserUid = uid
                    status = "Captured UID: \(uid)"
                } else {
                    let reason = (json["reason"] as? String) ?? "unknown"
                    status = "Capture failed: \(reason)"
                }
            } else {
                status = "Failed to parse capture response"
            }
        }
    }
}

fileprivate struct RepresentedWebView: NSViewRepresentable {
    @Binding var webView: WKWebView?
    let startURL: URL

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let wv = WKWebView(frame: .zero, configuration: config)
        let version = (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? ""
        wv.customUserAgent = "RemindersMenubar/" + version
        wv.navigationDelegate = context.coordinator
        wv.load(URLRequest(url: startURL))
        DispatchQueue.main.async { self.webView = wv }
        return wv
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator() }

    class Coordinator: NSObject, WKNavigationDelegate {
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            NotificationCenter.default.post(name: .WKWebViewURLDidChange, object: webView)
        }
        func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
            NotificationCenter.default.post(name: .WKWebViewURLDidChange, object: webView)
        }
    }
}

extension Notification.Name {
    static let WKWebViewURLDidChange = Notification.Name("WKWebViewURLDidChange")
}

extension WebSignInView {
    static func showWindow() {
        let viewController = NSHostingController(rootView: WebSignInView())
        let windowController = NSWindowController(window: NSWindow(contentViewController: viewController))
        if let window = windowController.window {
            window.title = "Sign In"
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.styleMask = [.titled, .closable, .resizable]
        }
        windowController.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
