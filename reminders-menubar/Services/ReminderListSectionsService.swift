import AppKit
import SQLite3

struct ReminderListSectionInfo: Identifiable, Equatable {
    let id: String
    let title: String
}

struct ReminderListSections: Equatable {
    var sectionsByCalendarIdentifier: [String: [ReminderListSectionInfo]] = [:]
    var sectionIdentifierByReminderIdentifier: [String: String] = [:]

    // Splits a list into its Reminders sections: reminders outside any section first, without a title,
    // then every section of the list that holds reminders, in order. Tag lists are never split.
    func groups(in section: ReminderListSection) -> [ReminderSectionGroup] {
        let unsectionedGroupId = "\(section.id)-unsectioned"
        guard case .calendar(let list, _) = section,
              let listSections = sectionsByCalendarIdentifier[list.id] else {
            return [ReminderSectionGroup(id: unsectionedGroupId, title: nil, reminders: section.reminders)]
        }

        let listSectionIds = Set(listSections.map(\.id))
        let remindersBySectionId = Dictionary(grouping: section.reminders) { reminderItem -> String? in
            let sectionId = sectionIdentifierByReminderIdentifier[reminderItem.id]
            return sectionId.flatMap { listSectionIds.contains($0) ? $0 : nil }
        }

        let unsectionedGroup = ReminderSectionGroup(
            id: unsectionedGroupId,
            title: nil,
            reminders: remindersBySectionId[nil, default: []]
        )
        return [unsectionedGroup] + listSections.compactMap { listSection in
            remindersBySectionId[listSection.id].map {
                ReminderSectionGroup(id: listSection.id, title: listSection.title, reminders: $0)
            }
        }
    }
}

// One entry of a list's `ZMEMBERSHIPSOFREMINDERSINSECTIONSASDATA` JSON. A nil groupID means
// the reminder was taken out of its section.
private struct ReminderSectionMembership: Decodable {
    let memberID: String
    let groupID: String?
    let modifiedOn: Double?
}

private struct ReminderSectionMemberships: Decodable {
    let memberships: [ReminderSectionMembership]
}

// A list's `ZSECTIONIDSORDERINGASDATA` JSON.
private struct ReminderSectionOrdering: Decodable {
    let orderedIdentifiers: [String]
}

// EventKit does not expose the sections of a reminder list. Reminders keeps them in its
// Core Data stores, which this service reads (never writes) through a folder the user
// selects once, so the sandbox only grants read access to that folder.
@MainActor
final class ReminderListSectionsService: ObservableObject {
    static let shared = ReminderListSectionsService()

    @Published private(set) var isUnavailable = false

    private init() {}

    private static let bookmarkOptions: URL.BookmarkCreationOptions = [
        .withSecurityScope,
        .securityScopeAllowOnlyReadAccess
    ]

    // NSHomeDirectory() returns the sandbox container, so the real home comes from the user database.
    private static let storesFolderURL = URL(fileURLWithPath: String(cString: getpwuid(getuid()).pointee.pw_dir))
        .appendingPathComponent("Library/Group Containers/group.com.apple.reminders/Container_v1/Stores")

    // Asks the user to select the Reminders stores folder and keeps a read-only bookmark to it.
    // Returns false when the user cancels or selects a folder without Reminders stores.
    func requestStoresFolderAccess() -> Bool {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.directoryURL = Self.storesFolderURL
        panel.message = rmbLocalized(.reminderListSectionsFolderPanelMessage)
        panel.prompt = rmbLocalized(.reminderListSectionsFolderPanelButton)

        NSApp.activate(ignoringOtherApps: true)
        guard panel.runModal() == .OK, let url = panel.url else {
            return false
        }

        let hasStores = withSecurityScope(url) { storeURLs(in: url).isEmpty == false }
        guard hasStores,
              let bookmark = try? url.bookmarkData(options: Self.bookmarkOptions) else {
            return false
        }

        UserPreferences.shared.reminderListSectionsFolderBookmark = bookmark
        isUnavailable = false
        return true
    }

    func fetchSections(for calendarIdentifiers: [String]) -> ReminderListSections {
        guard UserPreferences.shared.showReminderListSections else {
            isUnavailable = false
            return ReminderListSections()
        }

        guard let folderURL = resolveStoresFolder() else {
            isUnavailable = true
            return ReminderListSections()
        }

        let result = withSecurityScope(folderURL) {
            readSections(from: storeURLs(in: folderURL), for: Set(calendarIdentifiers))
        }
        isUnavailable = result == nil
        return result ?? ReminderListSections()
    }

    private func resolveStoresFolder() -> URL? {
        guard let bookmark = UserPreferences.shared.reminderListSectionsFolderBookmark else {
            return nil
        }

        var isStale = false
        guard let url = try? URL(
            resolvingBookmarkData: bookmark,
            options: .withSecurityScope,
            bookmarkDataIsStale: &isStale
        ) else {
            return nil
        }

        if isStale,
           let refreshedBookmark = withSecurityScope(url, {
               try? url.bookmarkData(options: Self.bookmarkOptions)
           }) {
            UserPreferences.shared.reminderListSectionsFolderBookmark = refreshedBookmark
        }
        return url
    }

    private func withSecurityScope<T>(_ url: URL, _ body: () -> T) -> T {
        let didStartAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        return body()
    }

    private func storeURLs(in folderURL: URL) -> [URL] {
        let fileURLs = (try? FileManager.default.contentsOfDirectory(
            at: folderURL,
            includingPropertiesForKeys: nil
        )) ?? []
        return fileURLs.filter {
            $0.lastPathComponent.hasPrefix("Data-") && $0.pathExtension == "sqlite"
        }
    }

    // Returns nil when no store could be read, so callers fall back to the flat list.
    private func readSections(from storeURLs: [URL], for calendarIdentifiers: Set<String>) -> ReminderListSections? {
        var sections = ReminderListSections()
        var didReadAnyStore = false

        for storeURL in storeURLs {
            guard let storeSections = readSections(from: storeURL, for: calendarIdentifiers) else {
                continue
            }
            didReadAnyStore = true
            sections.sectionsByCalendarIdentifier.merge(storeSections.sectionsByCalendarIdentifier) { $0 + $1 }
            sections.sectionIdentifierByReminderIdentifier.merge(
                storeSections.sectionIdentifierByReminderIdentifier
            ) { current, _ in current }
        }

        return didReadAnyStore ? sections : nil
    }

    private func readSections(from storeURL: URL, for calendarIdentifiers: Set<String>) -> ReminderListSections? {
        var database: OpaquePointer?
        defer { sqlite3_close(database) }
        guard sqlite3_open_v2(storeURL.path, &database, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else {
            return nil
        }

        let sectionRows = query(database, """
            SELECT list.ZCKIDENTIFIER, section.ZCKIDENTIFIER, section.ZDISPLAYNAME
            FROM ZREMCDBASESECTION section
            JOIN ZREMCDBASELIST list ON section.ZLIST = list.Z_PK
            WHERE section.ZMARKEDFORDELETION = 0
            ORDER BY section.ZCREATIONDATE
            """)
        let listRows = query(database, """
            SELECT ZCKIDENTIFIER,
                   CAST(ZMEMBERSHIPSOFREMINDERSINSECTIONSASDATA AS TEXT),
                   CAST(ZSECTIONIDSORDERINGASDATA AS TEXT)
            FROM ZREMCDBASELIST
            WHERE ZMEMBERSHIPSOFREMINDERSINSECTIONSASDATA IS NOT NULL
               OR ZSECTIONIDSORDERINGASDATA IS NOT NULL
            """)
        guard let sectionRows, let listRows else {
            return nil
        }

        var sections = ReminderListSections()
        for row in sectionRows where calendarIdentifiers.contains(row[0]) {
            sections.sectionsByCalendarIdentifier[row[0], default: []].append(
                ReminderListSectionInfo(id: row[1], title: row[2])
            )
        }

        for row in listRows {
            if let listSections = sections.sectionsByCalendarIdentifier[row[0]] {
                sections.sectionsByCalendarIdentifier[row[0]] = ordered(listSections, by: row[2])
            }
        }

        let sectionIdentifiers = Set(sections.sectionsByCalendarIdentifier.values.joined().map(\.id))
        for row in listRows where calendarIdentifiers.contains(row[0]) {
            for membership in decodeMemberships(row[1]) {
                if let groupID = membership.groupID, sectionIdentifiers.contains(groupID) {
                    sections.sectionIdentifierByReminderIdentifier[membership.memberID] = groupID
                } else {
                    sections.sectionIdentifierByReminderIdentifier[membership.memberID] = nil
                }
            }
        }
        return sections
    }

    // Sorted oldest first: a reminder can appear more than once, and its latest entry wins.
    private func decodeMemberships(_ json: String) -> [ReminderSectionMembership] {
        guard let decoded = try? JSONDecoder().decode(ReminderSectionMemberships.self, from: Data(json.utf8)) else {
            return []
        }
        return decoded.memberships.sorted { ($0.modifiedOn ?? 0) < ($1.modifiedOn ?? 0) }
    }

    // Reminders stores an order only once sections are reordered. Sections missing from it
    // keep their creation order, after the ordered ones.
    private func ordered(_ sections: [ReminderListSectionInfo], by orderingJSON: String) -> [ReminderListSectionInfo] {
        let decoded = try? JSONDecoder().decode(ReminderSectionOrdering.self, from: Data(orderingJSON.utf8))
        var seenIds = Set<String>()
        let orderedSections = (decoded?.orderedIdentifiers ?? [])
            .filter { seenIds.insert($0).inserted }
            .compactMap { id in sections.first { $0.id == id } }
        let orderedIds = Set(orderedSections.map(\.id))
        return orderedSections + sections.filter { !orderedIds.contains($0.id) }
    }

    private func query(_ database: OpaquePointer?, _ sql: String) -> [[String]]? {
        var statement: OpaquePointer?
        defer { sqlite3_finalize(statement) }
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK else {
            return nil
        }

        var rows: [[String]] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            rows.append((0..<sqlite3_column_count(statement)).map { column in
                sqlite3_column_text(statement, column).map { String(cString: $0) } ?? ""
            })
        }
        return rows
    }
}
