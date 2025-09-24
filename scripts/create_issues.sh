#!/usr/bin/env bash
set -euo pipefail

REPO="${1:-zulumonkeymetallic/bob-reminders-menubar}"

if ! command -v gh >/dev/null 2>&1; then
  echo "Error: GitHub CLI (gh) is required. Install from https://cli.github.com/" >&2
  exit 1
fi

if ! gh repo view "$REPO" >/dev/null 2>&1; then
  echo "Error: Cannot view repo $REPO. Check auth and repo name." >&2
  exit 1
fi

create() {
  local title="$1" body="$2" labels="$3"
  echo "Creating: $title"
  gh issue create -R "$REPO" -t "$title" -b "$body" -l "$labels"
}

create "Sync: Use Firestore WriteBatch for updates" \
"Reduce network roundtrips by batching reminderId/status updates with Firestore WriteBatch.\n\nScope:\n- Replace per-document setData() in FirebaseSyncService with a single WriteBatch commit.\n- Consider retry/backoff strategy and partial failure logging.\n- Keep summary/logging intact.\n\nBenefits: faster syncs, fewer network calls, smaller error surface." \
"enhancement,performance,firebase"

create "Sync: Harden idempotency by pre-writing reminderId mapping" \
"Further reduce duplicates by writing the reminderId mapping to Firestore immediately after creation and before any potential failure points.\n\nScope:\n- After creating an EKReminder, set reminderId on the corresponding Firestore task synchronously (batched).\n- Keep 'BOB: taskId=…' parsing as a fallback check.\n\nBenefits: protects against duplicates when later writes fail." \
"enhancement,reliability,firebase"

create "Refactor FirebaseSyncService to an actor for Swift concurrency safety" \
"Eliminate concurrency warnings and ensure main-actor operations are isolated.\n\nScope:\n- Convert FirebaseSyncService into an actor or isolate mutable state.\n- Keep RemindersService calls on MainActor.\n- Add small unit tests around duplicate detection parsing.\n\nBenefits: safer concurrency, cleaner async code." \
"enhancement,technical-debt,swift"

create "UI: Show sync results with errors and open-log action" \
"Improve visibility of sync outcomes beyond console logs.\n\nScope:\n- Present a transient sheet/toast with created/updated counts and first few errors.\n- Add a button to Open Log Folder (~/Library/Logs/RemindersMenuBar).\n- Persist last sync summary (already present) with a ‘View details’ action.\n\nBenefits: better UX and troubleshooting." \
"enhancement,ux"

create "Settings: Theme→Calendar mapping controls" \
"Allow users to manage how themes map to calendars and override automatic creation.\n\nScope:\n- Add a settings UI to map theme names to specific calendars (create/use/ignore).\n- Optionally allow per-theme default due date/time behavior.\n\nBenefits: predictable organization for synced reminders." \
"enhancement,settings"

create "Background sync: NSBackgroundActivityScheduler" \
"Offer an optional periodic background sync using NSBackgroundActivityScheduler.\n\nScope:\n- User toggle + interval selection.\n- Respect Reminders/Firebase authorization state.\n- Log summary and errors as usual.\n\nBenefits: hands-free keeping reminders in sync." \
"enhancement,background"

create "Auth: Conditional UI + status indicator" \
"Polish the FirebaseAuthView and settings menu.\n\nScope:\n- Hide/disable Google Sign-In controls when GoogleSignIn isn’t available.\n- Show current auth status (anonymous / Google / signed out) in the menu.\n- Add quick ‘Sign out’ and ‘Re-authenticate’ actions.\n\nBenefits: clearer authentication flow." \
"enhancement,ux,auth"

create "Localization: Add strings for Firebase auth + sync UI" \
"Localize newly added UI strings (Firebase, Google, errors, buttons).\n\nScope:\n- Add to string catalogs.\n- Provide base English and outline for existing locales.\n\nBenefits: consistent localization coverage." \
"enhancement,localization"

create "Sync: Preflight Reminders authorization with friendly error" \
"Ensure sync checks Reminders authorization before attempting writes.\n\nScope:\n- If not authorized, show a concise alert and link to System Settings › Privacy & Security › Reminders.\n- Skip sync work when unauthorized, but log an explicit reason.\n\nBenefits: clearer failures and fewer silent errors." \
"enhancement,reliability"

create "Sync: Add dry-run to preview changes" \
"Let users preview which reminders would be created/updated without applying them.\n\nScope:\n- A ‘Dry run’ checkbox in the Firebase menu.\n- Render a quick list of planned operations.\n\nBenefits: safer operation and confidence before applying changes." \
"enhancement,ux"

create "Logging: Rotate sync.log and add timestamps per line" \
"Improve long-term logging ergonomics.\n\nScope:\n- Implement simple log rotation (size- or date-based).\n- Prefix every log line with ISO8601 timestamps.\n\nBenefits: easier support and log file hygiene." \
"enhancement,maintenance"

create "CI: Add a minimal Xcode build action" \
"Add a GitHub Actions workflow that resolves packages and builds Debug.\n\nScope:\n- macOS runner, ‘xcodebuild -scheme \"Reminders MenuBar\"’.\n- Cache SPM dependencies.\n\nBenefits: ensures PRs remain buildable." \
"enhancement,ci"

echo "Done."

