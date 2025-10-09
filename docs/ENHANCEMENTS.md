# Enhancements

This fork implements the items below. Future work can iterate further, but core flow is working.

Implemented

1) Sync batching with Firestore WriteBatch
   - Batched updates for reminderId/status/title/due and orphan clears.

2) Idempotency: pre-write `reminderId` mapping
   - After creating a Reminder, immediately writes the mapping in the same batch.

3) Concurrency safety
   - `FirebaseSyncService` is now an `actor`. Reminders calls run on `MainActor`.

4) Sync feedback UI + open logs
   - Bottom toast with +created/↺updated/⚠︎errors.
   - Menu entries to open sync log and the logs folder.

5) Theme→Calendar mapping controls
   - Window to manage mappings; used during sync to route creations.

6) Background sync
   - Toggle + interval selection, via `NSBackgroundActivityScheduler`.

7) Auth UX signal
   - Auth view shows status and supports Google/custom/anonymous paths.

8) Localization hygiene
   - Avoids empty-path bundle warnings; new strings currently English-only.

9) Sync preflight: Reminders authorization
   - Pre-check with helpful message; handles macOS 14 `fullAccess`.

10) Dry-run mode
   - Toggle to simulate sync without writing to Reminders/Firestore.

11) Log rotation
   - Simple size-based rotation with ISO8601 timestamps.

12) CI build
   - GitHub Actions workflow for macOS builds (code signing disabled).

Potential next steps

- Conflict policy settings (Firestore vs Reminders as source of truth).
- Batched retries with backoff; partial failure surfacing in UI.
- Deeper localization coverage for new UI.

Recent changes (Reminders/Bob sync)

- Set `source` to `MacApp` on imported tasks; include `createdBy: "mac_app"`, `persona: "personal"`, and `serverUpdatedAt` in Firestore payload.
  - See reminders-menubar/Services/FirebaseSyncService.swift:349–356.
- Enriched BOB note metadata to aid deduplication: header now includes `ownerUid`, `source`, `reminderId` alongside `taskId/taskRef/status/due/listId/list`.
  - See reminders-menubar/Services/FirebaseSyncService.swift:169–185, 369–382, 638–645, 1151–1156, 1231–1234.
- Mac app dedup writes now use `duplicateKey` (plus `duplicateOf`, `status: 2`) for parity with Bob backend.
  - See reminders-menubar/Services/FirebaseSyncService.swift:871–878.
- Bob compatibility updates: allow `MacApp` as task source in types and backend scoring/dedup utilities.
  - /Users/jim/GitHub/bob/react-app/src/types.ts:118, /Users/jim/GitHub/bob/functions/index.js:250, 3138.

- Recurring reminders ignored
  - Sync now skips reminders with recurrence rules (no import or updates for repeating items).
  - See guards in reminders-menubar/Services/FirebaseSyncService.swift around reminder scans.

- Tag sync with inheritance + conversion tags
  - When pushing Reminders→Bob, task `tags` are merged with inherited `storyRef`, `goalRef`, and `theme`.
  - When Bob→Reminders, Firestore `tags` are merged with inherited values, and conversion adds `convertedtostory`.
  - Conversion also completes the associated reminder and annotates the note/tags.
