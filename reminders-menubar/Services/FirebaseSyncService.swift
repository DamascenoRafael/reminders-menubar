import Foundation
import EventKit

#if canImport(FirebaseFirestore) && canImport(FirebaseAuth)
import FirebaseFirestore
import FirebaseAuth

struct FbTask {
    let id: String
    let title: String
    let dueDate: Double?
    let reminderId: String?
    let status: Any?
    let storyId: String?
    let goalId: String?
    let reference: String?
    let updatedAt: Date?
}

// swiftlint:disable cyclomatic_complexity function_body_length type_body_length file_length
actor FirebaseSyncService {
    static let shared = FirebaseSyncService()
    private init() {}

    private var reportedPermissionContexts: Set<String> = []
    private var lastThemeMappingRefresh: Date?
    private let themeMappingThrottle: TimeInterval = 300
    private var cachedRemoteThemeNames: [String] = []

    private struct StoryContext {
        var storyRef: String?
        var themeName: String?
        var sprintId: String?
        var sprintName: String?
        var goalRef: String?
    }

    private struct GoalContext {
        var ref: String?
        var themeName: String?
    }

    private let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private func recordPermissionIfNeeded(_ error: Error, context: String) {
        guard let nsError = error as NSError?, nsError.domain == FirestoreErrorDomain else { return }
        guard let code = FirestoreErrorCode.Code(rawValue: nsError.code), code == .permissionDenied else { return }
        if reportedPermissionContexts.insert(context).inserted {
            SyncLogService.shared.logEvent(tag: "firestore", level: "ERROR", message: "Permission denied for \(context). Bob token may lack read access.")
        }
    }

    private func isoNow() -> String { isoFormatter.string(from: Date()) }

    private func isoString(forMillis millis: Double) -> String {
        isoFormatter.string(from: Date(timeIntervalSince1970: millis / 1000.0))
    }

    private func stringValue(for value: Any?) -> String? {
        guard let value else { return nil }
        if let str = value as? String {
            let trimmed = str.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }
        if let number = value as? NSNumber {
            return number.stringValue
        }
        if let dict = value as? [String: Any] {
            let keys = ["list", "calendar", "title", "name", "value"]
            for key in keys {
                if let extracted = stringValue(for: dict[key]) {
                    return extracted
                }
            }
        }
        if let array = value as? [Any] {
            for element in array {
                if let extracted = stringValue(for: element) {
                    return extracted
                }
            }
        }
        return nil
    }

    private func parseBobNote(notes: String?) -> (meta: [String: String], userLines: [String]) {
        guard let notes, !notes.isEmpty else { return ([:], []) }
        let lines = notes.components(separatedBy: "\n")
        guard let header = lines.first, header.hasPrefix("BOB:") else {
            return ([:], lines)
        }

        var meta: [String: String] = [:]
        let tokens = header.dropFirst(4).split(separator: " ")
        for token in tokens {
            let pair = token.split(separator: "=", maxSplits: 1)
            guard pair.count == 2 else { continue }
            let key = String(pair[0]).trimmingCharacters(in: .whitespaces)
            let value = String(pair[1])
            if !key.isEmpty, !value.isEmpty { meta[key] = value }
        }

        var idx = 1
        while idx < lines.count, lines[idx].hasPrefix("#") {
            let line = lines[idx]
            if line.hasPrefix("#sprint: ") {
                meta["sprint"] = String(line.dropFirst("#sprint: ".count))
            } else if line.hasPrefix("#theme: ") {
                meta["theme"] = String(line.dropFirst("#theme: ".count))
            } else if line.hasPrefix("#story: ") {
                meta["storyRef"] = String(line.dropFirst("#story: ".count))
            } else if line.hasPrefix("#task: ") {
                meta["taskRef"] = String(line.dropFirst("#task: ".count))
            } else if line.hasPrefix("#goal: ") {
                meta["goalRef"] = String(line.dropFirst("#goal: ".count))
            } else if line.hasPrefix("#tags: ") {
                meta["tags"] = String(line.dropFirst("#tags: ".count))
            }
            idx += 1
        }

        let userLines: [String]
        if idx < lines.count {
            userLines = Array(lines[idx...])
        } else {
            userLines = []
        }
        return (meta, userLines)
    }

    private func composeBobNote(meta: [String: String], userLines: [String]) -> String {
        var tokens: [String] = []
        let orderedKeys = ["taskId", "taskRef", "storyId", "storyRef", "goalId", "goalRef", "status", "due", "synced"]
        for key in orderedKeys {
            if let value = meta[key], !value.isEmpty {
                tokens.append("\(key)=\(value)")
            }
        }
        let header = tokens.isEmpty ? "BOB:" : "BOB: " + tokens.joined(separator: " ")

        var lines: [String] = [header]
        if let sprint = meta["sprint"], !sprint.isEmpty { lines.append("#sprint: \(sprint)") }
        if let theme = meta["theme"], !theme.isEmpty { lines.append("#theme: \(theme)") }
        if let story = meta["storyRef"], !story.isEmpty { lines.append("#story: \(story)") }
        if let taskRef = meta["taskRef"], !taskRef.isEmpty { lines.append("#task: \(taskRef)") }
        if let goalRef = meta["goalRef"], !goalRef.isEmpty { lines.append("#goal: \(goalRef)") }
        if let tags = meta["tags"], !tags.isEmpty { lines.append("#tags: \(tags)") }

        if !userLines.isEmpty {
            if !(userLines.first?.isEmpty ?? true) { lines.append("") }
            lines.append(contentsOf: userLines)
        }

        return lines.joined(separator: "\n")
    }

    func refreshThemeMappingFromRemote(force: Bool = false) async {
        let now = Date()
        if !force, let last = lastThemeMappingRefresh, now.timeIntervalSince(last) < themeMappingThrottle {
            return
        }

        guard let db = FirebaseManager.shared.db else { return }
        guard let user = Auth.auth().currentUser else { return }

        do {
            let snapshot = try await db.collection("themes").whereField("ownerUid", isEqualTo: user.uid).getDocuments()
            guard !snapshot.isEmpty else {
                lastThemeMappingRefresh = now
                cachedRemoteThemeNames = []
                SyncLogService.shared.logEvent(tag: "themes", level: "INFO", message: "No Bob themes available; retaining existing theme→list mappings")
                return
            }

            var nameToList: [String: String] = [:]
            var allNames: Set<String> = []
            let listKeys = ["reminderList", "reminderListName", "list", "listName", "remindersList", "remindersListName", "calendar", "calendarName"]
            for doc in snapshot.documents {
                let data = doc.data()
                let themeNameRaw = stringValue(for: data["name"]) ?? stringValue(for: data["title"]) ?? stringValue(for: data["reference"]) ?? doc.documentID
                let themeName = themeNameRaw.trimmingCharacters(in: .whitespacesAndNewlines)
                if themeName.isEmpty { continue }
                allNames.insert(themeName)

                var listName: String?
                for key in listKeys {
                    if let value = data[key] {
                        listName = stringValue(for: value)
                    }
                    if listName != nil { break }
                }
                if listName == nil, let metadata = data["metadata"] as? [String: Any] {
                    for key in listKeys {
                        if let value = metadata[key] {
                            listName = stringValue(for: value)
                        }
                        if listName != nil { break }
                    }
                }
                if let listName, !listName.isEmpty {
                    nameToList[themeName] = listName
                }
            }

            cachedRemoteThemeNames = allNames.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
            var calendars = await MainActor.run { RemindersService.shared.getCalendars() }
            guard !calendars.isEmpty else {
                lastThemeMappingRefresh = now
                SyncLogService.shared.logEvent(tag: "themes", level: "WARN", message: "Skipped remote theme mappings: no Reminders lists available")
                return
            }

            var resolved: [String: String] = [:]
            var unresolved: [String: String] = [:]
            for (theme, listName) in nameToList {
                if let calendar = calendars.first(where: { $0.title.caseInsensitiveCompare(listName) == .orderedSame }) {
                    resolved[theme] = calendar.calendarIdentifier
                    continue
                }

                let created = await MainActor.run { RemindersService.shared.ensureCalendar(named: listName) }
                if let created {
                    resolved[theme] = created.calendarIdentifier
                    calendars.append(created)
                    SyncLogService.shared.logEvent(tag: "themes", level: "INFO", message: "Created Reminders list \(listName) for theme \(theme)")
                } else {
                    unresolved[theme] = listName
                }
            }

            if !resolved.isEmpty {
                let resolvedSnapshot = resolved
                await MainActor.run {
                    var combined = UserPreferences.shared.themeCalendarMap
                    combined.merge(resolvedSnapshot) { _, new in new }
                    UserPreferences.shared.themeCalendarMap = combined
                }
                SyncLogService.shared.logEvent(tag: "themes", level: "INFO", message: "Loaded \(resolved.count) theme→list mappings from Firestore")
            } else {
                SyncLogService.shared.logEvent(tag: "themes", level: "WARN", message: "No remote theme mappings matched local Reminders lists")
            }

            if !unresolved.isEmpty {
                let sample = Array(unresolved.prefix(3)).map { "\($0.key)->\($0.value)" }.joined(separator: ", ")
                SyncLogService.shared.logEvent(tag: "themes", level: "WARN", message: "Unresolved theme mappings: \(unresolved.count). Samples: \(sample)")
            }

            lastThemeMappingRefresh = now
        } catch {
            recordPermissionIfNeeded(error, context: "themes")
            SyncLogService.shared.logError(tag: "themes", error: error)
        }
    }

    func themeNames() -> [String] {
        cachedRemoteThemeNames
    }

    private func statusString(for statusValue: Any?) -> String {
        isDone(statusValue) ? "complete" : "open"
    }

    private func parseISO(_ string: String?) -> Date? {
        guard let string else { return nil }
        return isoFormatter.date(from: string)
    }

    private func importReminderToBob(reminder: EKReminder, ownerUid: String, db: Firestore, dryRun: Bool) async throws -> FbTask {
        let title = await MainActor.run { reminder.title ?? "" }
        let reminderIdentifier = await MainActor.run { reminder.calendarItemIdentifier }
        let isCompleted = await MainActor.run { reminder.isCompleted }
        let dueDate = await MainActor.run { reminder.dueDateComponents?.date }
        let dueMillis = dueDate.map { $0.timeIntervalSince1970 * 1000.0 }

        var data: [String: Any] = [
            "ownerUid": ownerUid,
            "title": title,
            "status": isCompleted ? 2 : 0,
            "reminderId": reminderIdentifier,
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ]
        if let dueMillis { data["dueDate"] = dueMillis }

        let doc = db.collection("tasks").document()
        if !dryRun {
            try await doc.setData(data)
        }

        let existingNotes = await MainActor.run { reminder.notes }
        let (_, userLines) = parseBobNote(notes: existingNotes)

        var meta: [String: String] = [
            "taskId": doc.documentID,
            "status": isCompleted ? "complete" : "open",
            "synced": isoNow()
        ]
        if let dueMillis { meta["due"] = isoString(forMillis: dueMillis) }

        let newNotes = composeBobNote(meta: meta, userLines: userLines)
        if !dryRun {
            await MainActor.run {
                reminder.notes = newNotes
                RemindersService.shared.save(reminder: reminder)
            }
        }

        var importMeta: [String: Any] = [
            "title": title,
            "status": isCompleted ? "complete" : "open"
        ]
        if let dueMillis { importMeta["due"] = isoString(forMillis: dueMillis) }
        importMeta["taskRef"] = doc.documentID
        SyncLogService.shared.logSyncDetail(
            direction: .toBob,
            action: "importReminder",
            taskId: doc.documentID,
            storyId: nil,
            metadata: importMeta,
            dryRun: dryRun
        )

        return FbTask(
            id: doc.documentID,
            title: title,
            dueDate: dueMillis,
            reminderId: reminderIdentifier,
            status: isCompleted ? 2 : 0,
            storyId: nil,
            goalId: nil,
            reference: nil,
            updatedAt: Date()
        )
    }

    private func toTask(_ doc: DocumentSnapshot) -> FbTask? {
        let data = doc.data() ?? [:]
        let updatedAt: Date?
        if let ts = data["updatedAt"] as? Timestamp {
            updatedAt = ts.dateValue()
        } else if let date = data["updatedAt"] as? Date {
            updatedAt = date
        } else {
            updatedAt = nil
        }

        return FbTask(
            id: doc.documentID,
            title: data["title"] as? String ?? "Task",
            dueDate: (data["dueDate"] as? NSNumber)?.doubleValue ?? data["dueDate"] as? Double,
            reminderId: data["reminderId"] as? String,
            status: data["status"],
            storyId: data["storyId"] as? String,
            goalId: data["goalId"] as? String,
            reference: (data["reference"] as? String) ?? (data["ref"] as? String) ?? (data["shortId"] as? String) ?? (data["code"] as? String),
            updatedAt: updatedAt
        )
    }

    // Bidirectional sync between Firestore tasks and Apple Reminders.
    // - Creates Reminders for tasks without reminderId
    // - Updates fields both directions (title, due, completion)
    // - Clears mappings for tasks whose reminders are gone
    // - Best-effort delete: if task has deleted flag, remove reminder
    func syncNow(targetCalendar preferredCalendar: EKCalendar?) async -> (created: Int, updated: Int, errors: [String]) {
        guard AppConstants.useNativeReminders else {
            return (0, 0, ["Native Reminders integration disabled"])
        }
        // Preflight: ensure Reminders access is granted
        let hasAccess = await MainActor.run { RemindersService.shared.hasFullRemindersAccess() }
        guard hasAccess else { return (0, 0, ["Reminders access not granted"]) }

        guard let user = Auth.auth().currentUser, let db = FirebaseManager.shared.db else {
            return (0, 0, ["Not authenticated or Firebase not configured"])
        }
        await refreshThemeMappingFromRemote(force: false)
        let dryRun = await MainActor.run { UserPreferences.shared.syncDryRun }
        var created = 0
        var updated = 0
        var errors: [String] = []
        var createdLinkedStories = 0
        var createdWithTheme = 0

        var storyContextCache: [String: StoryContext] = [:]
        var sprintCache: [String: String?] = [:]
        var goalContextCache: [String: GoalContext] = [:]

        func fetchSprintName(_ sprintId: String) async -> String? {
            if let cached = sprintCache[sprintId] {
                return cached ?? nil
            }
            do {
                let sprintSnapshot = try await db.collection("sprints").document(sprintId).getDocument()
                if let sprintData = sprintSnapshot.data() {
                    let name = (sprintData["name"] as? String) ?? (sprintData["title"] as? String)
                    sprintCache[sprintId] = name
                    return name
                }
            } catch {
                recordPermissionIfNeeded(error, context: "sprints/\(sprintId)")
            }
            sprintCache[sprintId] = nil
            return nil
        }

        func fetchGoalContext(_ goalId: String) async -> GoalContext {
            if let cached = goalContextCache[goalId] {
                return cached
            }
            var ctx = GoalContext()
            do {
                let goalSnapshot = try await db.collection("goals").document(goalId).getDocument()
                if let goalData = goalSnapshot.data() {
                    ctx.ref = (goalData["reference"] as? String) ?? (goalData["ref"] as? String) ?? (goalData["code"] as? String)
                    ctx.themeName = (goalData["themeId"] as? String) ?? (goalData["theme"] as? String)
                }
            } catch {
                recordPermissionIfNeeded(error, context: "goals/\(goalId)")
            }
            if ctx.ref == nil { ctx.ref = goalId }
            goalContextCache[goalId] = ctx
            return ctx
        }

        func fetchStoryContext(storyId: String?, goalId: String?) async -> StoryContext {
            if let sid = storyId, let cached = storyContextCache[sid] {
                return cached
            }

            var ctx = StoryContext()
            var resolvedGoalId = goalId

            if let sid = storyId {
                do {
                    let storySnapshot = try await db.collection("stories").document(sid).getDocument()
                    if let storyData = storySnapshot.data() {
                        ctx.storyRef = (storyData["reference"] as? String) ?? (storyData["ref"] as? String) ?? (storyData["shortId"] as? String) ?? (storyData["code"] as? String) ?? sid
                        ctx.themeName = (storyData["themeId"] as? String) ?? (storyData["theme"] as? String)
                        if let sprintId = storyData["sprintId"] as? String {
                            ctx.sprintId = sprintId
                            ctx.sprintName = await fetchSprintName(sprintId)
                        }
                        if let goalFromStory = storyData["goalId"] as? String {
                            resolvedGoalId = goalFromStory
                        }
                    } else {
                        ctx.storyRef = sid
                    }
                } catch {
                    recordPermissionIfNeeded(error, context: "stories/\(sid)")
                    ctx.storyRef = sid
                }
            }

            if let gid = resolvedGoalId {
                let goalCtx = await fetchGoalContext(gid)
                if ctx.themeName == nil { ctx.themeName = goalCtx.themeName }
                ctx.goalRef = goalCtx.ref ?? gid
            } else if let gid = goalId {
                let goalCtx = await fetchGoalContext(gid)
                if ctx.themeName == nil { ctx.themeName = goalCtx.themeName }
                ctx.goalRef = goalCtx.ref ?? gid
            }

            if ctx.sprintName == nil, let sprintId = ctx.sprintId {
                ctx.sprintName = await fetchSprintName(sprintId)
            }

            if ctx.storyRef == nil, let sid = storyId {
                ctx.storyRef = sid
            }
            if ctx.goalRef == nil, let gid = goalId {
                ctx.goalRef = gid
            }

            if let sid = storyId {
                storyContextCache[sid] = ctx
            }

            return ctx
        }

        do {
            // Load candidate tasks
            let taskQuerySnapshot = try await db.collection("tasks").whereField("ownerUid", isEqualTo: user.uid).getDocuments()
            var tasks = taskQuerySnapshot.documents.compactMap(toTask)
            let tasksWithoutReminders = tasks.filter { $0.reminderId == nil && !isDone($0.status) }
            var taskById: [String: FbTask] = Dictionary(uniqueKeysWithValues: tasks.map { ($0.id, $0) })

            // Index existing reminders by taskId to avoid duplicates
            let lookupEventStore = EKEventStore()
            let lookupCalendars: [EKCalendar] = await MainActor.run { RemindersService.shared.getCalendars() }
            let lookupPredicate = lookupEventStore.predicateForReminders(in: lookupCalendars)
            let existingReminders: [EKReminder] = await withCheckedContinuation { continuation in
                lookupEventStore.fetchReminders(matching: lookupPredicate) {
                    continuation.resume(returning: $0 ?? [])
                }
            }
            var existingTaskIds: Set<String> = []
            existingReminders.forEach { reminder in
                if let firstNoteLine = reminder.notes?.split(separator: "\n").first, firstNoteLine.hasPrefix("BOB:") {
                    let tokens = firstNoteLine.replacingOccurrences(of: "BOB:", with: "").split(separator: " ")
                    for token in tokens {
                        let keyValue = token.split(separator: "=")
                        if keyValue.count == 2 && keyValue[0] == "taskId" {
                            existingTaskIds.insert(String(keyValue[1]))
                        }
                    }
                }
            }

            // Decide which tasks need reminders created
            var toCreate = tasksWithoutReminders.filter { !existingTaskIds.contains($0.id) }

            // Map reminders by identifier for quick lookup
            var remindersById: [String: EKReminder] = [:]
            existingReminders.forEach { remindersById[$0.calendarItemIdentifier] = $0 }

            var unsyncedReminders: [EKReminder] = []
            for reminder in existingReminders {
                let notes = await MainActor.run { reminder.notes }
                let meta = parseBobNote(notes: notes).meta
                if meta["taskId"] == nil {
                    unsyncedReminders.append(reminder)
                }
            }

            for reminder in unsyncedReminders {
                do {
                    let imported = try await importReminderToBob(reminder: reminder, ownerUid: user.uid, db: db, dryRun: dryRun)
                    if !dryRun {
                        existingTaskIds.insert(imported.id)
                        if let reminderKey = imported.reminderId { remindersById[reminderKey] = reminder }
                        tasks.append(imported)
                        taskById[imported.id] = imported
                    }
                } catch {
                    let title = await MainActor.run { reminder.title ?? "" }
                    errors.append("Import reminder failed for \(title): \(error.localizedDescription)")
                }
            }

            struct DuplicateInfo {
                let task: FbTask
                let reason: String
                let key: String
                let survivorId: String
            }

            var duplicatesToComplete: [String: DuplicateInfo] = [:]

            var tasksByReminderId: [String: [FbTask]] = [:]
            for task in tasks {
                if let rid = task.reminderId, !rid.isEmpty {
                    tasksByReminderId[rid, default: []].append(task)
                }
            }

            for (reminderId, group) in tasksByReminderId where group.count > 1 {
                let sorted = group.sorted { ($0.updatedAt ?? Date.distantPast) > ($1.updatedAt ?? Date.distantPast) }
                guard let survivor = sorted.first else { continue }
                for duplicate in sorted.dropFirst() {
                    if duplicatesToComplete[duplicate.id] == nil {
                        duplicatesToComplete[duplicate.id] = DuplicateInfo(task: duplicate, reason: "duplicateReminderId", key: reminderId, survivorId: survivor.id)
                    }
                }
            }

            var tasksByReference: [String: [FbTask]] = [:]
            for task in tasks {
                if let reference = task.reference?.lowercased(), !reference.isEmpty {
                    tasksByReference[reference, default: []].append(task)
                }
            }

            for (reference, group) in tasksByReference where group.count > 1 {
                let sorted = group.sorted { ($0.updatedAt ?? Date.distantPast) > ($1.updatedAt ?? Date.distantPast) }
                guard let survivor = sorted.first else { continue }
                for duplicate in sorted.dropFirst() {
                    if duplicatesToComplete[duplicate.id] == nil {
                        duplicatesToComplete[duplicate.id] = DuplicateInfo(task: duplicate, reason: "duplicateTaskRef", key: reference, survivorId: survivor.id)
                    }
                }
            }

            let duplicateIds = Set(duplicatesToComplete.keys)
            if !duplicateIds.isEmpty {
                tasks.removeAll { duplicateIds.contains($0.id) }
                duplicateIds.forEach { taskById.removeValue(forKey: $0) }
                toCreate.removeAll { duplicateIds.contains($0.id) }
            }

            let duplicateInfos = Array(duplicatesToComplete.values)

            // Prepare a batch for Firestore updates
            let batch = db.batch()

            for info in duplicateInfos {
                var payload: [String: Any] = [
                    "status": 2,
                    "updatedAt": FieldValue.serverTimestamp(),
                    "duplicateOf": info.survivorId,
                    "duplicateReason": info.reason
                ]
                if let reminderId = info.task.reminderId, !reminderId.isEmpty {
                    payload["reminderId"] = reminderId
                }
                if !dryRun {
                    let ref = db.collection("tasks").document(info.task.id)
                    batch.setData(payload, forDocument: ref, merge: true)
                }
                var logMeta: [String: Any] = [
                    "reason": info.reason,
                    "duplicateKey": info.key,
                    "keptTaskId": info.survivorId
                ]
                if let reminderId = info.task.reminderId { logMeta["reminderId"] = reminderId }
                if let taskRef = info.task.reference { logMeta["taskRef"] = taskRef }
                SyncLogService.shared.logSyncDetail(direction: .toBob, action: "completeDuplicateTask", taskId: info.task.id, storyId: info.task.storyId, metadata: logMeta, dryRun: dryRun)
            }

            for task in toCreate {
                let context = await fetchStoryContext(storyId: task.storyId, goalId: task.goalId)
                let themeName = context.themeName
                let sprintName = context.sprintName
                let storyRef = context.storyRef
                let goalRef = context.goalRef
                let taskRefValue = (task.reference?.isEmpty == false) ? task.reference! : task.id
                // Resolve calendar using theme→calendar mapping if available
                let cal: EKCalendar? = await MainActor.run {
                    if let name = themeName {
                        if let mappedId = UserPreferences.shared.themeCalendarMap[name],
                           let mapped = RemindersService.shared.getCalendar(withIdentifier: mappedId) {
                            return mapped
                        }
                        return RemindersService.shared.ensureCalendar(named: name)
                    }
                    return preferredCalendar ?? RemindersService.shared.getDefaultCalendar()
                }
                guard let cal = cal else { continue }

                // Skip if a reminder with this taskId already exists
                if existingTaskIds.contains(task.id) {
                    continue
                }

                var rmb = RmbReminder()
                rmb.title = task.title
                if let due = task.dueDate { rmb.hasDueDate = true; rmb.hasTime = false; rmb.date = Date(timeIntervalSince1970: due/1000.0) }
                rmb.calendar = cal

                var noteMeta: [String: String] = [
                    "taskId": task.id,
                    "status": statusString(for: task.status),
                    "synced": isoNow()
                ]
                if let sid = task.storyId { noteMeta["storyId"] = sid }
                if let gid = task.goalId { noteMeta["goalId"] = gid }
                if let due = task.dueDate { noteMeta["due"] = isoString(forMillis: due) }
                if let storyRef { noteMeta["storyRef"] = storyRef }
                if let goalRef { noteMeta["goalRef"] = goalRef }
                noteMeta["taskRef"] = taskRefValue
                if let sprintName { noteMeta["sprint"] = sprintName }
                if let sprintName { noteMeta["tags"] = sprintName }
                if let themeName { noteMeta["theme"] = themeName }
                rmb.notes = composeBobNote(meta: noteMeta, userLines: [])

                let reminderToCreate = rmb
                let rid: String? = await MainActor.run {
                    guard !dryRun, let saved = RemindersService.shared.createNew(with: reminderToCreate, in: cal) else { return nil }
                    var tagsChanged = false
                    if saved.rmbUpdateTag(newTag: sprintName, removing: nil) {
                        tagsChanged = true
                    }
                    if tagsChanged {
                        RemindersService.shared.save(reminder: saved)
                    }
                    return saved.calendarItemIdentifier
                }
                var creationMeta: [String: Any] = [
                    "title": task.title,
                    "calendar": cal.title,
                    "status": statusString(for: task.status)
                ]
                if let due = task.dueDate { creationMeta["due"] = isoString(forMillis: due) }
                if let themeName { creationMeta["theme"] = themeName }
                if let sprintName { creationMeta["sprint"] = sprintName }
                if let storyRef { creationMeta["storyRef"] = storyRef }
                if let goalRef { creationMeta["goalRef"] = goalRef }
                creationMeta["taskRef"] = taskRefValue
                if let gid = task.goalId { creationMeta["goalId"] = gid }
                SyncLogService.shared.logSyncDetail(direction: .toReminders, action: "createReminder", taskId: task.id, storyId: task.storyId, metadata: creationMeta, dryRun: dryRun)
                created += 1
                if task.storyId != nil { createdLinkedStories += 1 }
                if themeName != nil { createdWithTheme += 1 }

                // Pre-write mapping idempotently
                if let rid {
                    let ref = db.collection("tasks").document(task.id)
                    batch.setData(["updatedAt": FieldValue.serverTimestamp(), "reminderId": rid], forDocument: ref, merge: true)
                }
            }

            // Refresh and push mapping + completions + field updates back to Firestore
            let store = EKEventStore()
            let calendars: [EKCalendar] = await MainActor.run { RemindersService.shared.getCalendars() }
            let predicate = store.predicateForReminders(in: calendars)
            let all: [EKReminder] = await withCheckedContinuation { cont in
                store.fetchReminders(matching: predicate) { cont.resume(returning: $0 ?? []) }
            }
            for reminder in all {
                let notes = await MainActor.run { reminder.notes }
                let parsed = parseBobNote(notes: notes)
                guard let tid = parsed.meta["taskId"], !tid.isEmpty else { continue }
                let rid = reminder.calendarItemIdentifier
                let ref = db.collection("tasks").document(tid)
                let title = await MainActor.run { reminder.title ?? "" }
                let calendarTitle = await MainActor.run { reminder.calendar.title }
                let completed = await MainActor.run { reminder.isCompleted }
                let dueDate = await MainActor.run { reminder.dueDateComponents?.date }

                var data: [String: Any] = [
                    "updatedAt": FieldValue.serverTimestamp(),
                    "reminderId": rid,
                    "title": title,
                    "status": completed ? 2 : 0
                ]
                if let dueDate {
                    data["dueDate"] = dueDate.timeIntervalSince1970 * 1000.0
                } else {
                    data["dueDate"] = FieldValue.delete()
                }
                if !dryRun {
                    batch.setData(data, forDocument: ref, merge: true)
                }

                var pushMeta: [String: Any] = [
                    "title": title,
                    "calendar": calendarTitle,
                    "status": completed ? "complete" : "open"
                ]
                if let dueDate { pushMeta["due"] = isoFormatter.string(from: dueDate) }
                if let storyRef = parsed.meta["storyRef"] { pushMeta["storyRef"] = storyRef }
                if let taskRef = parsed.meta["taskRef"] { pushMeta["taskRef"] = taskRef }
                if let goalRef = parsed.meta["goalRef"] { pushMeta["goalRef"] = goalRef }
                if pushMeta["taskRef"] == nil, let task = taskById[tid] {
                    let taskRefValue = (task.reference?.isEmpty == false) ? task.reference! : task.id
                    pushMeta["taskRef"] = taskRefValue
                }
                if pushMeta["storyRef"] == nil || pushMeta["goalRef"] == nil {
                    let context = await fetchStoryContext(storyId: taskById[tid]?.storyId, goalId: taskById[tid]?.goalId)
                    if pushMeta["storyRef"] == nil, let storyRef = context.storyRef { pushMeta["storyRef"] = storyRef }
                    if pushMeta["goalRef"] == nil, let goalRef = context.goalRef { pushMeta["goalRef"] = goalRef }
                }
                SyncLogService.shared.logSyncDetail(direction: .toBob, action: "mergeReminder", taskId: tid, storyId: parsed.meta["storyId"], metadata: pushMeta, dryRun: dryRun)
                updated += 1
            }

            // Pull updates from Firestore to Reminders for tasks that already have reminderId
            for task in tasks {
                guard let rid = task.reminderId, let reminder = remindersById[rid] else { continue }

                let context = await fetchStoryContext(storyId: task.storyId, goalId: task.goalId)

                let notes = await MainActor.run { reminder.notes }
                var (meta, userLines) = parseBobNote(notes: notes)
                let reminderTitle = await MainActor.run { reminder.title ?? "" }
                let reminderCompleted = await MainActor.run { reminder.isCompleted }
                let reminderDueDate = await MainActor.run { reminder.dueDateComponents?.date }
                let reminderLastModified = await MainActor.run { reminder.lastModifiedDate ?? Date.distantPast }
                let metaSynced = parseISO(meta["synced"]) ?? Date.distantPast
                let reminderEffectiveUpdated = max(reminderLastModified, metaSynced)
                let bobUpdated = task.updatedAt ?? Date.distantPast
                let nowIso = isoNow()

                let reminderIsNewer = reminderEffectiveUpdated > bobUpdated
                let bobIsNewer = bobUpdated > reminderEffectiveUpdated

                let ref = db.collection("tasks").document(task.id)

                var reminderChanged = false
                var metaChanged = false

                if reminderIsNewer {
                    var pushData: [String: Any] = [
                        "updatedAt": FieldValue.serverTimestamp(),
                        "title": reminderTitle,
                        "status": reminderCompleted ? 2 : 0,
                        "reminderId": rid
                    ]
                    if let due = reminderDueDate {
                        pushData["dueDate"] = due.timeIntervalSince1970 * 1000.0
                    } else {
                        pushData["dueDate"] = FieldValue.delete()
                    }
                    if let storyRef = context.storyRef { pushData["storyRef"] = storyRef }
                    if let theme = context.themeName { pushData["theme"] = theme }
                    if let sprintId = context.sprintId { pushData["sprintId"] = sprintId }
                    if let goalRef = context.goalRef { pushData["goalRef"] = goalRef }
                    if let taskRef = task.reference, !taskRef.isEmpty { pushData["reference"] = taskRef }

                    if !dryRun {
                        batch.setData(pushData, forDocument: ref, merge: true)
                    }

                    var logMeta: [String: Any] = [
                        "title": reminderTitle,
                        "status": reminderCompleted ? "complete" : "open"
                    ]
                    if let due = reminderDueDate { logMeta["due"] = isoFormatter.string(from: due) }
                    if let storyRef = context.storyRef { logMeta["storyRef"] = storyRef }
                    let taskRefValue = (task.reference?.isEmpty == false) ? task.reference! : task.id
                    logMeta["taskRef"] = taskRefValue
                    if let goalRef = context.goalRef { logMeta["goalRef"] = goalRef }
                    SyncLogService.shared.logSyncDetail(direction: .toBob, action: "updateFromReminder", taskId: task.id, storyId: task.storyId, metadata: logMeta, dryRun: dryRun)

                    meta["status"] = reminderCompleted ? "complete" : "open"
                    if let due = reminderDueDate { meta["due"] = isoFormatter.string(from: due) } else { meta.removeValue(forKey: "due") }
                    meta["synced"] = nowIso
                    metaChanged = true
                    if !dryRun { updated += 1 }
                } else if bobIsNewer {
                    let currentCalendarId = await MainActor.run { reminder.calendar.calendarIdentifier }
                    var movedCalendarName: String?
                    if let themeName = context.themeName {
                        let mappedIdentifier = UserPreferences.shared.themeCalendarMap[themeName]
                        let expectedCalendar = await MainActor.run { () -> EKCalendar? in
                            if let mappedIdentifier,
                               let cal = RemindersService.shared.getCalendar(withIdentifier: mappedIdentifier) {
                                return cal
                            }
                            let existing = RemindersService.shared.getCalendars().first { $0.title.caseInsensitiveCompare(themeName) == .orderedSame }
                            if existing != nil || dryRun {
                                return existing
                            }
                            return RemindersService.shared.ensureCalendar(named: themeName)
                        }
                        if let expectedCalendar,
                           expectedCalendar.calendarIdentifier != currentCalendarId {
                            movedCalendarName = expectedCalendar.title
                            if !dryRun {
                                await MainActor.run { RemindersService.shared.move(reminder: reminder, to: expectedCalendar) }
                            }
                            reminderChanged = true
                            metaChanged = true
                        }
                    }

                    if reminderTitle != task.title {
                        if !dryRun {
                            await MainActor.run { reminder.title = task.title }
                        }
                        reminderChanged = true
                    }

                    if let due = task.dueDate {
                        let date = Date(timeIntervalSince1970: due / 1000.0)
                        if reminderDueDate != date {
                            if !dryRun {
                                await MainActor.run { reminder.dueDateComponents = date.dateComponents(withTime: false) }
                            }
                            reminderChanged = true
                        }
                        meta["due"] = isoString(forMillis: due)
                    } else if reminderDueDate != nil {
                        if !dryRun {
                            await MainActor.run { reminder.dueDateComponents = nil }
                        }
                        reminderChanged = true
                        meta.removeValue(forKey: "due")
                    }

                    let shouldBeCompleted = isDone(task.status)
                    if reminderCompleted != shouldBeCompleted {
                        if !dryRun {
                            await MainActor.run { reminder.isCompleted = shouldBeCompleted }
                        }
                        reminderChanged = true
                    }
                    meta["status"] = shouldBeCompleted ? "complete" : "open"
                    meta["synced"] = nowIso
                    metaChanged = true

                    var detailMeta: [String: Any] = [
                        "title": task.title,
                        "status": meta["status"] ?? "unknown"
                    ]
                    if let due = task.dueDate { detailMeta["due"] = isoString(forMillis: due) }
                    if let storyRef = context.storyRef { detailMeta["storyRef"] = storyRef }
                    let taskRefValue = (task.reference?.isEmpty == false) ? task.reference! : task.id
                    detailMeta["taskRef"] = taskRefValue
                    if let goalRef = context.goalRef { detailMeta["goalRef"] = goalRef }
                    if let movedCalendarName { detailMeta["calendar"] = movedCalendarName }
                    SyncLogService.shared.logSyncDetail(direction: .toReminders, action: "updateReminderFromBob", taskId: task.id, storyId: task.storyId, metadata: detailMeta, dryRun: dryRun)
                }

                if meta["taskId"] != task.id { meta["taskId"] = task.id; metaChanged = true }
                let storyIdValue = task.storyId
                if let storyIdValue {
                    if meta["storyId"] != storyIdValue { meta["storyId"] = storyIdValue; metaChanged = true }
                } else if meta.removeValue(forKey: "storyId") != nil {
                    metaChanged = true
                }
                let previousSprintTag = meta["tags"]

                if let goal = task.goalId {
                    if meta["goalId"] != goal { meta["goalId"] = goal; metaChanged = true }
                } else if meta.removeValue(forKey: "goalId") != nil {
                    metaChanged = true
                }
                if let storyRef = context.storyRef {
                    if meta["storyRef"] != storyRef { meta["storyRef"] = storyRef; metaChanged = true }
                } else if meta.removeValue(forKey: "storyRef") != nil {
                    metaChanged = true
                }
                let taskRefValue = (task.reference?.isEmpty == false) ? task.reference! : task.id
                if meta["taskRef"] != taskRefValue {
                    meta["taskRef"] = taskRefValue
                    metaChanged = true
                }
                if let goalRef = context.goalRef {
                    if meta["goalRef"] != goalRef { meta["goalRef"] = goalRef; metaChanged = true }
                } else if meta.removeValue(forKey: "goalRef") != nil {
                    metaChanged = true
                }
                if let theme = context.themeName {
                    if meta["theme"] != theme { meta["theme"] = theme; metaChanged = true }
                } else if meta.removeValue(forKey: "theme") != nil {
                    metaChanged = true
                }
                if let sprint = context.sprintName {
                    if meta["sprint"] != sprint { meta["sprint"] = sprint; metaChanged = true }
                    if meta["tags"] != sprint { meta["tags"] = sprint; metaChanged = true }
                } else {
                    if meta.removeValue(forKey: "sprint") != nil { metaChanged = true }
                    if meta.removeValue(forKey: "tags") != nil { metaChanged = true }
                }

                let updatedSprintTag = meta["tags"]
                let tagChanged = await MainActor.run {
                    reminder.rmbUpdateTag(newTag: updatedSprintTag, removing: previousSprintTag)
                }
                if tagChanged { reminderChanged = true }

                let newNotes = composeBobNote(meta: meta, userLines: userLines)
                if newNotes != notes {
                    if !dryRun {
                        await MainActor.run { reminder.notes = newNotes }
                    }
                    reminderChanged = true
                }

                if (reminderChanged || metaChanged) {
                    if !dryRun {
                        await MainActor.run { RemindersService.shared.save(reminder: reminder) }
                        if bobIsNewer { updated += 1 }
                    }
                }

                taskById[task.id] = task
            }

            // Tasks with reminderId whose reminder no longer exists → clear mapping
            let reminderIdsSet = Set(all.map { $0.calendarItemIdentifier })
            let orphanTasks = tasks.filter { if let rid = $0.reminderId { return !reminderIdsSet.contains(rid) } else { return false } }
            for orphanTask in orphanTasks {
                let ref = db.collection("tasks").document(orphanTask.id)
                if !dryRun {
                    batch.setData(["updatedAt": FieldValue.serverTimestamp(), "reminderId": FieldValue.delete(), "reminderMissingAt": FieldValue.serverTimestamp()], forDocument: ref, merge: true)
                }
                let context = await fetchStoryContext(storyId: orphanTask.storyId, goalId: orphanTask.goalId)
                var orphanMeta: [String: Any] = ["reason": "reminder missing"]
                let orphanTaskRef = (orphanTask.reference?.isEmpty == false) ? orphanTask.reference! : orphanTask.id
                orphanMeta["taskRef"] = orphanTaskRef
                if let storyRef = context.storyRef { orphanMeta["storyRef"] = storyRef }
                if let goalRef = context.goalRef { orphanMeta["goalRef"] = goalRef }
                SyncLogService.shared.logSyncDetail(direction: .toBob, action: "clearMissingReminder", taskId: orphanTask.id, storyId: orphanTask.storyId, metadata: orphanMeta, dryRun: dryRun)
                updated += 1
            }

            // Best-effort delete: if the task indicates deletion, remove the reminder
            for task in tasks {
                guard let rid = task.reminderId, let reminder = remindersById[rid] else { continue }
                let context = await fetchStoryContext(storyId: task.storyId, goalId: task.goalId)
                let deleted = (task.status as? String)?.lowercased() == "deleted" || (task.status as? NSNumber)?.intValue == -1
                if deleted {
                    if !dryRun {
                        let wasCompleted = await MainActor.run { reminder.isCompleted }
                        await MainActor.run { reminder.isCompleted = true }
                        let notes = await MainActor.run { reminder.notes }
                        var (meta, userLines) = parseBobNote(notes: notes)
                        meta["taskId"] = task.id
                        if let story = task.storyId { meta["storyId"] = story } else { meta.removeValue(forKey: "storyId") }
                        if let goal = task.goalId { meta["goalId"] = goal } else { meta.removeValue(forKey: "goalId") }
                        if let storyRef = context.storyRef { meta["storyRef"] = storyRef } else { meta.removeValue(forKey: "storyRef") }
                        if let goalRef = context.goalRef { meta["goalRef"] = goalRef } else { meta.removeValue(forKey: "goalRef") }
                        let taskRefValue = (task.reference?.isEmpty == false) ? task.reference! : task.id
                        meta["taskRef"] = taskRefValue
                        meta["status"] = "complete"
                        meta["synced"] = isoNow()
                        let newNotes = composeBobNote(meta: meta, userLines: userLines)
                        if newNotes != notes {
                            await MainActor.run { reminder.notes = newNotes }
                        }
                        await MainActor.run { RemindersService.shared.save(reminder: reminder) }
                        if !wasCompleted { updated += 1 }
                    }
                    let reminderTitle = await MainActor.run { reminder.title ?? "" }
                    var completionMeta: [String: Any] = ["title": reminderTitle]
                    let taskRefValue = (task.reference?.isEmpty == false) ? task.reference! : task.id
                    completionMeta["taskRef"] = taskRefValue
                    if let storyRef = context.storyRef { completionMeta["storyRef"] = storyRef }
                    if let goalRef = context.goalRef { completionMeta["goalRef"] = goalRef }
                    SyncLogService.shared.logSyncDetail(direction: .toReminders, action: "markCompleteFromBobDelete", taskId: task.id, storyId: task.storyId, metadata: completionMeta, dryRun: dryRun)
                }
            }

            // Commit batched writes
            if !dryRun {
                do { try await batch.commit() } catch { errors.append("Batch commit failed: \(error.localizedDescription)") }
            }

        } catch {
            errors.append("Firestore query failed: \(error.localizedDescription)")
        }

        // Persist summary
        let summary = "created=\(created) updated=\(updated) stories=\(createdLinkedStories) themes=\(createdWithTheme)"
        await MainActor.run {
            UserPreferences.shared.lastSyncSummary = summary
            UserPreferences.shared.lastSyncDate = Date()
        }
        SyncLogService.shared.logSync(userId: user.uid, created: created, updated: updated, linkedStories: createdLinkedStories, themed: createdWithTheme, errors: errors)

        return (created, updated, errors)
    }

    private func isDone(_ status: Any?) -> Bool {
        if let numberStatus = status as? NSNumber { return numberStatus.intValue == 2 }
        if let stringStatus = status as? String { return stringStatus.lowercased() == "done" || stringStatus == "2" }
        return false
    }
}
// swiftlint:enable cyclomatic_complexity function_body_length type_body_length

#else

actor FirebaseSyncService {
    static let shared = FirebaseSyncService()
    private init() {}
    func syncNow(targetCalendar: EKCalendar?) async -> (created: Int, updated: Int, errors: [String]) {
        return (0, 0, ["Firebase SDK not available"])
    }
}

#endif
