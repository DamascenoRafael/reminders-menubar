# Enhancement Proposals

GitHub Issues are currently disabled on this fork, so this document tracks proposed enhancements. If you enable Issues in the repository settings, you can create issues from these items (see also `scripts/create_issues.sh`).

1) Sync: Use Firestore WriteBatch for updates
   - Rationale: Reduce network roundtrips and partial-failure surface.
   - Scope: Batch reminderId/status updates; add retry/backoff; keep summary/logging.

2) Sync: Harden idempotency by pre-writing reminderId mapping
   - Rationale: Avoid duplicates when later writes fail.
   - Scope: Immediately write `reminderId` after creation (batched); keep BOB header parsing as fallback.

3) Concurrency: Refactor FirebaseSyncService to an actor
   - Rationale: Eliminate concurrency warnings and ensure safe access.
   - Scope: Actor-ize service or isolate mutable state; keep Reminders calls on MainActor; add small unit tests.

4) UI: Show sync results with errors + Open Log
   - Rationale: Better visibility of outcomes and troubleshooting.
   - Scope: Transient sheet/toast with created/updated/error count; button to open `~/Library/Logs/RemindersMenuBar`.

5) Settings: Theme→Calendar mapping controls
   - Rationale: Predictable organization for synced reminders.
   - Scope: Map themes to calendars; allow per-theme overrides and opt-out.

6) Background sync via NSBackgroundActivityScheduler
   - Rationale: Hands‑free periodic sync.
   - Scope: Toggle + interval; respect auth states; log summary/errors.

7) Auth UX: Conditional UI + status indicator
   - Rationale: Clearer authentication flow.
   - Scope: Hide Google controls if package absent; show status (anonymous/Google/signed out); quick sign out/re-auth.

8) Localization: Add strings for new UI
   - Rationale: Keep localization coverage consistent.
   - Scope: String catalogs for auth/sync UI; provide base English; hook into existing locales.

9) Sync preflight: Reminders authorization
   - Rationale: Avoid silent failures when unauthorized.
   - Scope: Pre-check Reminders access; friendly alert with System Settings deep link; explicit log reason.

10) Dry-run mode for sync
   - Rationale: Safer operation and confidence.
   - Scope: Checkbox in menu; preview planned creates/updates.

11) Logging ergonomics: rotate sync.log, per-line timestamps
   - Rationale: Log hygiene and easier support.
   - Scope: Simple rotation (size/date); ISO8601 timestamps each line.

12) CI: Minimal Xcode build workflow
   - Rationale: Keep PRs buildable.
   - Scope: GitHub Actions; resolve packages; Debug build; cache SPM.

