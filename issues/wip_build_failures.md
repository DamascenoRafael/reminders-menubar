# Build Failures – WIP Full Sync Enhancements

## 1. Linker stops with `errno=28`
- **Symptom**: `ld: write() failed, errno=28` while producing `Reminders MenuBar.debug.dylib`.
- **Diagnosis**: macOS linker reports `errno=28` → no space left on device when writing the linked binary under `DerivedData`.
- **Suggested Fixes**:
  - Clear `~/Library/Developer/Xcode/DerivedData/reminders-menubar-*` to free space.
  - Ensure the volume hosting DerivedData (and `/tmp` if redirected) has several GB free before building.
  - Optionally set a custom, roomier `-derivedDataPath` for this project.

## 2. SwiftLint load from dependencies (resolved)
- Earlier builds flagged identifier-style violations in Swift Package samples (GoogleSignIn, GoogleDataTransport, Promises).
- **Resolution**: `.swiftlint.yml` now excludes `build/` and `SourcePackages/` so third-party code no longer triggers lint errors. Keep this exclusion when adding new packages.

## 3. Swift compile fails in `FirebaseSyncService` (resolved)
- **Symptom**: `cannot find 't' in scope` at `FirebaseSyncService.swift:588`, `:637`, `:639`.
- **Diagnosis**: Refactor from `t` → `task` in the sync loops was only partially applied; the new code still referenced `t` when preparing Firestore push payloads and reminder updates.
- **Fix**: Remaining identifiers updated to `task` (07 Jul 2024), followed by a successful run of `xcodebuild -scheme "Reminders MenuBar" -configuration Debug -sdk macosx build`.
- **Follow-up Recommendation**: Add unit/integration coverage for reminder↔task merge paths so future renames stay safe.
