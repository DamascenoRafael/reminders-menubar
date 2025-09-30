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
