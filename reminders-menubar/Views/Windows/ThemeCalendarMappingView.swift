import SwiftUI
import EventKit
#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif
#if canImport(FirebaseAuth)
import FirebaseAuth
#endif

struct ThemeCalendarMappingView: View {
    @ObservedObject var prefs = UserPreferences.shared
    @ObservedObject var firebase = FirebaseManager.shared
    @State private var newTheme: String = ""
    @State private var selectedListId: String? = nil
    @State private var lists: [EKCalendar] = []
    @State private var availableThemes: [String] = []
    @State private var isLoadingThemes = false
    @State private var themeLoadError: String?
    @State private var hasLoggedPermissionError = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Theme → List Mapping").font(.title2).fontWeight(.semibold)

            HStack(spacing: 8) {
                TextField("Theme name", text: $newTheme)
                    .textFieldStyle(.roundedBorder)
                    .frame(minWidth: 200)
                Menu("Bob Themes") {
                    if isLoadingThemes {
                        Text("Loading…")
                    }
                    if !availableThemes.isEmpty {
                        ForEach(availableThemes, id: \.self) { theme in
                            Button(theme) { newTheme = theme }
                        }
                    }
                    Button("Refresh") {
                        Task {
                            await FirebaseSyncService.shared.refreshThemeMappingFromRemote(force: true)
                            await loadAvailableThemes(force: true)
                        }
                    }
                }
                .disabled(isLoadingThemes && availableThemes.isEmpty)
                Picker("List", selection: $selectedListId) {
                    Text("Select…").tag(Optional<String>.none)
                    ForEach(lists, id: \.calendarIdentifier) { calendar in
                        Text(calendar.title).tag(Optional(calendar.calendarIdentifier))
                    }
                }
                .labelsHidden()
                Button("Add/Update") { addMapping() }.disabled((newTheme.trimmingCharacters(in: .whitespaces).isEmpty) || selectedListId == nil)
            }
            if let error = themeLoadError {
                Text(error).font(.footnote).foregroundColor(.secondary)
            } else if isLoadingThemes {
                Text("Loading Bob themes…").font(.footnote).foregroundColor(.secondary)
            } else if !availableThemes.isEmpty && newTheme.isEmpty {
                Text("Select a Bob theme or type one to map it to a list.").font(.footnote).foregroundColor(.secondary)
            }

            List {
                ForEach(prefs.themeCalendarMap.keys.sorted(), id: \.self) { themeKey in
                    HStack {
                        Text(themeKey)
                        Spacer()
                        let mappedIdentifier = prefs.themeCalendarMap[themeKey]
                        Text(listTitle(for: mappedIdentifier)).foregroundColor(.secondary)
                        Button("Remove") { prefs.themeCalendarMap.removeValue(forKey: themeKey) }
                    }
                }
            }

            HStack {
                Spacer()
                Button("Close") { closeWindow() }
            }
        }
        .padding(16)
        .frame(width: 520, height: 380)
        .onAppear {
            lists = RemindersService.shared.getCalendars()
            Task {
                await FirebaseSyncService.shared.refreshThemeMappingFromRemote(force: false)
                await loadAvailableThemes(force: false)
            }
        }
        .onChange(of: firebase.currentUser == nil ? "none" : "auth") { _ in
            Task {
                await FirebaseSyncService.shared.refreshThemeMappingFromRemote(force: true)
                await loadAvailableThemes(force: true)
            }
        }
    }

    private func listTitle(for id: String?) -> String {
        guard let id,
              let calendar = RemindersService.shared.getCalendar(withIdentifier: id) else { return "(missing)" }
        return calendar.title
    }

    private func addMapping() {
        guard let id = selectedListId else { return }
        let theme = newTheme.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !theme.isEmpty else { return }
        prefs.themeCalendarMap[theme] = id
        newTheme = ""
        selectedListId = nil
    }

    private func loadAvailableThemes(force: Bool) async {
#if canImport(FirebaseFirestore)
        if !FirebaseManager.shared.isConfigured {
            FirebaseManager.shared.configureIfNeeded()
        }
        let cachedNames = await FirebaseSyncService.shared.themeNames()
        if !force, !cachedNames.isEmpty {
            await MainActor.run {
                availableThemes = cachedNames
                isLoadingThemes = false
                themeLoadError = nil
            }
            return
        }
        if !force && !availableThemes.isEmpty { return }
        guard let db = FirebaseManager.shared.db else {
            let signedIn = FirebaseManager.shared.currentUser != nil
            await MainActor.run {
                availableThemes = []
                isLoadingThemes = false
                themeLoadError = signedIn ? "Unable to access Bob themes right now." : "Sign in through Bob Authentication to load themes."
            }
            if !signedIn {
                SyncLogService.shared.logEvent(tag: "themes", level: "WARN", message: "Theme picker skipped: user not authenticated")
            }
            return
        }
        #if canImport(FirebaseAuth)
        guard let currentUser = Auth.auth().currentUser else {
            await MainActor.run {
                isLoadingThemes = false
                availableThemes = []
                themeLoadError = "Sign in through Bob Authentication to load themes."
            }
            SyncLogService.shared.logEvent(tag: "themes", level: "WARN", message: "Theme picker skipped: missing authenticated user")
            return
        }
        #endif
        await MainActor.run {
            isLoadingThemes = true
            themeLoadError = nil
        }
        do {
            #if canImport(FirebaseAuth)
            let snapshot = try await db.collection("themes").whereField("ownerUid", isEqualTo: currentUser.uid).getDocuments()
            #else
            let snapshot = try await db.collection("themes").getDocuments()
            #endif
            let names = snapshot.documents.compactMap { doc -> String? in
                let data = doc.data()
                if let explicit = data["name"] as? String, !explicit.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    return explicit
                }
                return doc.documentID
            }
            let unique = Array(Set(names)).sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
            await MainActor.run {
                availableThemes = unique
                isLoadingThemes = false
                if unique.isEmpty {
                    themeLoadError = "No themes were found in Bob."
                }
            }
        } catch {
#if canImport(FirebaseAuth)
            if let nsError = error as NSError?,
               nsError.domain == FirestoreErrorDomain,
               FirestoreErrorCode.Code(rawValue: nsError.code) == .permissionDenied,
               let fallbackNames = try? await loadFallbackThemes(uid: currentUser.uid, db: db),
               !fallbackNames.isEmpty {
                await MainActor.run {
                    availableThemes = fallbackNames
                    isLoadingThemes = false
                    themeLoadError = nil
                }
                return
            }
#endif
            await MainActor.run {
                isLoadingThemes = false
                if let nsError = error as NSError?,
                   nsError.domain == FirestoreErrorDomain,
                   FirestoreErrorCode.Code(rawValue: nsError.code) == .permissionDenied {
                    themeLoadError = "Bob denied access to themes for this account. Using private theme settings instead."
                    if !hasLoggedPermissionError {
                        SyncLogService.shared.logEvent(tag: "themes", level: "ERROR", message: "Permission denied while loading themes for user. Update Firestore rules or token scopes.")
                        hasLoggedPermissionError = true
                    }
                } else {
                    themeLoadError = error.localizedDescription
                    SyncLogService.shared.logError(tag: "themes", error: error)
                }
            }
        }
#else
        await MainActor.run {
            availableThemes = []
            themeLoadError = "Firebase SDK not available in this build."
        }
#endif
    }

#if canImport(FirebaseAuth)
    private func loadFallbackThemes(uid: String, db: Firestore) async throws -> [String] {
        let snapshot = try await db.collection("global_themes").document(uid).getDocument()
        guard let data = snapshot.data() else { return [] }
        let names = extractThemeNames(from: data)
        if names.isEmpty {
            SyncLogService.shared.logEvent(tag: "themes", level: "WARN", message: "global_themes doc for \(uid) did not contain recognizable theme names")
        } else {
            SyncLogService.shared.logEvent(tag: "themes", level: "INFO", message: "Loaded \(names.count) themes from global_themes fallback for user \(uid)")
        }
        return names
    }

    private func extractThemeNames(from data: [String: Any]) -> [String] {
        var names: Set<String> = []

        func digest(_ value: Any) {
            switch value {
            case let arr as [Any]:
                arr.forEach(digest)
            case let dict as [String: Any]:
                if let name = dict["name"] as? String {
                    names.insert(name)
                }
                if let title = dict["title"] as? String {
                    names.insert(title)
                }
                dict.values.forEach(digest)
            case let str as String:
                if !str.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    names.insert(str)
                }
            default: break
            }
        }

        if let explicit = data["names"] {
            digest(explicit)
        }
        if let themes = data["themes"] {
            digest(themes)
        }
        digest(data)
        return names.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }
#endif

    private func closeWindow() { NSApp.keyWindow?.close() }

    static func showWindow() {
        let viewController = NSHostingController(rootView: ThemeCalendarMappingView())
        let windowController = NSWindowController(window: NSWindow(contentViewController: viewController))
        if let window = windowController.window {
            window.title = "Theme List Mapping"
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.animationBehavior = .alertPanel
            window.styleMask = [.titled, .closable]
        }
        windowController.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

struct ThemeCalendarMappingView_Previews: PreviewProvider {
    static var previews: some View { ThemeCalendarMappingView() }
}
