# Expected Operation

This document describes the intended end-to-end behaviour of the Reminders ⇄ Bob (Firestore) synchronisation layer as implemented in the current codebase.

It covers:

1. The data model and metadata we persist in Apple Reminders notes.
2. How Reminders are imported into Bob when no linkage exists yet.
3. How task updates propagate Bob → Reminders and Reminders → Bob, including conflict resolution.
4. The logging and dry-run diagnostics that accompany each operation.
5. Calendar selection, theme handling, and sprint tagging.
6. Known limitations / TODOs.

---

## 1. Metadata Schema (Reminders Notes)

Every reminder that participates in Bob sync starts with a canonical header followed by tagged lines. Example:

```
BOB: taskId=TASK-1234 taskRef=TASK-1234 storyId=STRY-0007 storyRef=STRY-7 goalId=GOAL-42 status=open due=2025-09-30T08:00:00Z synced=2025-09-30T10:15:02Z
#sprint: Sprint 32
#theme: Customer Delight
#task: TASK-1234
#story: STRY-7
#goal: GOAL-42
#tags: Sprint 32

<user-authored notes, if any>
```

**Key fields written & parsed:**

- `taskId`: Firestore task document ID – primary key for sync.
- `taskRef`: Human-readable task reference. Defaults to `taskId` if no reference exists.
- `storyId`: Firestore story ID (optional).
- `storyRef`: Human-readable story reference (optional).
- `goalId`: Firestore goal ID (optional).
- `goalRef`: Human-readable goal reference (optional).
- `status`: `open` or `complete` (derived from Firestore status / Reminder completion flag).
- `due`: ISO-8601 date/time string in UTC when a due date is present.
- `synced`: ISO-8601 timestamp for the last successful two-way reconciliation.
- `#sprint`: Friendly sprint name (if available from story context).
- `#theme`: Theme name associated with the story/goal (used for calendar mapping).
- `#tags`: Mirrors the sprint name to allow tag-based filtering in Reminders.
- `#task`, `#story`, `#goal`: Duplicate the respective references for user visibility.

The parser preserves arbitrary user text after the tagged lines and regenerates headers when metadata changes.

---

## 2. Reminder → Bob Initial Import

1. During each sync run we load every Reminder from the current event store scope.
2. Reminders missing a `BOB:` header are considered unsynchronised.
3. For each unsynchronised reminder we:
   - Create a **dry-run record** (if `syncDryRun` is enabled) and log the intended insert.
   - When not in dry run, create a new Firestore document in `tasks` with default fields:
     - `ownerUid`, `title`, `status`, `reminderId`, `dueDate`, `createdAt`, `updatedAt`.
   - Compose and write the canonical note header (with taskId, taskRef, status, due, synced).
   - Log an `updateFromReminder` detail entry.

Imported tasks adopt the reminder’s completion state, due date, and initial note content. Sprint/theme tagging is not inferred on import because it requires explicit human configuration.

---

## 3. Bidirectional Sync Logic

Each loop iteration fetches:

- Firestore tasks owned by the authenticated user.
- All Reminders in scope.
- Previously imported/linked tasks are paired using `taskId` and `reminderId`.

### 3.1 Determining the authoritative side

For a given pair we compute:

```
reminderEffectiveUpdated = max(reminder.lastModified, parsedMeta.synced)
bobUpdated             = task.updatedAt (Firestore server timestamp)
```

- If `reminderEffectiveUpdated > bobUpdated`: Reminder is newer → push fields to Firestore.
- If `bobUpdated > reminderEffectiveUpdated`: Bob is newer → pull fields into Reminder.
- Otherwise: data is already in sync; we still refresh the `synced` timestamp.

### 3.2 Fields propagated Reminder → Bob

When the reminder wins the conflict:

- Title, due date, completion flag become the source of truth.
- We compute the calendar name and include sprint/theme/story/goal references.
- Firestore `tasks/<id>` receives a merge update with:
  - `title`, `status`, `dueDate` (or deleted), `reminderId`, `storyRef` (human readable), `theme`, `sprintId`, `goalRef`, `reference` (taskRef) and `updatedAt`.
- We log an `updateFromReminder` detail record containing the same metadata.
- The reminder note header is updated to reflect the new state and `synced` timestamp.

### 3.3 Fields propagated Bob → Reminder

When the Firestore task wins the conflict:

- Reminder title, due date, and completion flag are updated.
- If the task’s theme implies a specific calendar (via `UserPreferences.themeCalendarMap`) we ensure the reminder resides in that calendar. When a new calendar name is needed we call `ensureCalendar`, or only log the intended move in dry-run mode.
- The reminder note is refreshed with story/task/goal refs, theme, sprint, tags, `due`, and `synced` timestamp.
- We log an `updateReminderFromBob` detail entry (includes moved calendar if changed).

### 3.4 Task creation → Reminder (Bob-only tasks)

For Firestore tasks lacking `reminderId`:

- We compute the story/goal context (story reference, goal reference, sprint name, theme) via cached helper functions.
- Select a calendar based on theme mapping or fallback to default.
- Create the reminder (skipping actual write in dry-run).
- Record `createReminder` log entries with comprehensive metadata.

### 3.5 Task deletion / missing reminders

- When Firestore reports `status` = deleted (`"deleted"` or `-1`), we mark the reminder complete, update the note, and log `markCompleteFromBobDelete`. Dry run only logs the planned change.
- When a task references a reminder ID that no longer exists, we clear `reminderId` in Firestore (unless dry-run) and log `clearMissingReminder` with task/story refs.

---

## 4. Logging & Dry-Run Diagnostics

`SyncLogService.logSyncDetail` writes JSON detail lines to `~/Library/Logs/RemindersMenuBar/sync.log`. Each line includes:

- Timestamp, direction (`toBob`, `toReminders`, `diagnostics`), action (e.g., `createReminder`, `updateFromReminder`, `mergeReminder`, `clearMissingReminder`, `importReminder`, `markCompleteFromBobDelete`).
- Task ID, story ID.
- A metadata object containing status, due ISO string, story/task/goal references, calendars moved, etc.
- `"dryRun": true` flag when `UserPreferences.syncDryRun` is enabled.

This gives full visibility into what will happen before executing writes.

---

## 5. Calendar & Theme Handling

- Theme names retrieved from stories/goals determine the desired reminder calendar.
- `UserPreferences.themeCalendarMap` expresses explicit mappings. If absent, we attempt to locate or (non-dry-run) create a calendar named after the theme.
- Reminders are moved into the correct calendar when Bob is the authoritative source and its theme differs from the current reminder calendar.

---

## 6. Known Limitations / TODOs

- **Simultaneous edits**: If title and due date are changed on both sides more or less simultaneously, the most recent timestamp wins; we do not attempt field-level merges.
- **Firehose context fields**: We do not currently infer story/goal references when Reminders are imported without any descriptive context. Users must maintain these via Bob.
- **Bulk migrations**: Large imports may take time; batching is already handled, but we do not show progress feedback in UI.
- **Calendar creation**: When running in dry-run mode we skip creating new calendars—logs record what would happen.
- **Attachment sync**: Notes beyond the BOB header remain untouched, but attachments / subtasks are not synchronised.

---

By adhering to the flows described above the sync engine keeps Bob tasks and Apple Reminders aligned, with transparent logging and the ability to simulate every write through dry-run mode before touching either data store.
