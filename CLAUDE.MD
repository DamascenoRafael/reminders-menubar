# CLAUDE.MD - AI Assistant Guide

This document provides context and guidance for AI assistants working on the Reminders MenuBar project.

## Project Overview

**Reminders MenuBar** is a macOS menu bar application that provides quick access to Apple Reminders. It allows users to view, create, edit, and manage their reminders directly from the menu bar, with full iCloud sync support.

### Key Features
- Native macOS menu bar integration
- Sync with Apple Reminders via EventKit
- Natural language date parsing for due dates
- Multi-language support (19+ languages)
- Light/Dark mode support
- Keyboard shortcuts
- Reminder prioritization and filtering

## Technology Stack

- **Language**: Swift
- **Frameworks**:
  - SwiftUI (UI framework)
  - EventKit (Apple Reminders integration via EKEventStore)
  - Combine (reactive programming)
- **Build System**: Xcode
- **Package Manager**: Swift Package Manager (implied)
- **Minimum macOS**: Big Sur (11.0)
- **License**: GNU General Public License v3.0

## Project Structure

```
reminders-menubar/
├── reminders-menubar/          # Main app source code
│   ├── AppDelegate.swift       # Main app delegate
│   ├── AppCommands.swift       # Menu bar commands
│   ├── Constants.swift         # App constants
│   ├── Models/                 # Data models
│   │   ├── RmbReminder.swift   # Core reminder model
│   │   ├── ReminderList.swift  # Reminder list model
│   │   └── RemindersData.swift # Main data container
│   ├── Services/               # Business logic services
│   │   ├── RemindersService.swift    # EventKit integration
│   │   ├── DateParser.swift          # Natural language date parsing
│   │   ├── UserPreferences.swift     # User settings
│   │   └── KeyboardShortcutService.swift
│   ├── Views/                  # SwiftUI views
│   ├── Resources/              # Localization and assets
│   └── Extensions/             # Swift extensions
├── reminders-menubar-launcher/ # Launch at login helper
├── docs/                       # Documentation and images
└── reminders-menubar.xcodeproj # Xcode project
```

## Key Components

### Models (reminders-menubar/Models/)
- **RmbReminder.swift**: Core reminder object wrapper around EKReminder
- **RemindersData.swift**: Central data store for all reminders
- **ReminderList.swift**: Reminder list/calendar representation
- **PrioritizedReminders.swift**: Handles reminder prioritization
- **ReminderInterval.swift**: Time-based filtering (today, week, etc.)

### Services (reminders-menubar/Services/)
- **RemindersService.swift**: Main service for EventKit operations (CRUD for reminders)
- **DateParser.swift**: Natural language date parsing ("tomorrow", "next week", etc.)
- **CalendarParser.swift**: Calendar-related parsing
- **PriorityParser.swift**: Priority level parsing
- **UserPreferences.swift**: Manages app settings and user preferences
- **KeyboardShortcutService.swift**: Global keyboard shortcut handling
- **GithubService.swift**: Update checking via GitHub releases

### Views (reminders-menubar/Views/)
SwiftUI views for the menu bar interface, settings, and reminder editing.

### Resources (reminders-menubar/Resources/)
- Localization files for 19+ languages
- Color scheme definitions (RmbColorScheme.swift, RmbColorKey.swift)
- App icons and assets

## Development Guidelines

### EventKit Integration
The app heavily relies on EventKit's `EKEventStore` for accessing reminders:
- Always request authorization before accessing reminders
- Handle authorization states properly
- Use `RemindersService.swift` as the main interface to EventKit
- Remember that EKReminder objects are managed by EventKit's calendar database

### Natural Language Processing
The `DateParser.swift` service handles natural language date inputs:
- Supports phrases like "tomorrow", "next week", "in 3 days"
- Localization-aware parsing
- Falls back gracefully for unrecognized inputs

### Localization
- All user-facing strings should be localized
- Currently supports: English, Brazilian Portuguese, Chinese (Simplified/Traditional), Czech, Dutch, Filipino, French, German, Indonesian, Italian, Japanese, Korean, Polish, Russian, Slovak, Spanish (Latin America), Turkish, Ukrainian, Vietnamese
- See `docs/adding-new-languages.md` for adding new languages
- Use `remindersLocalized.swift` for string localization

### SwiftUI Best Practices
- Follow declarative UI patterns
- Use `@State`, `@StateObject`, `@ObservedObject` appropriately
- Leverage Combine for reactive data flows
- Support both light and dark modes

### Code Style
- Follow SwiftLint rules (see `.swiftlint.yml`)
- Use clear, descriptive variable names
- Keep functions focused and single-purpose
- Document complex logic with comments

## Common Tasks

### Adding a New Feature
1. Identify the appropriate layer (Model, View, Service)
2. Update models if data structure changes
3. Add business logic to appropriate service
4. Create/update SwiftUI views
5. Add localization strings for all supported languages
6. Test with both light and dark modes
7. Verify EventKit permissions and edge cases

### Modifying Reminder Operations
- All reminder CRUD operations go through `RemindersService.swift`
- Changes to EKReminder objects must be saved via EventKit
- Consider sync implications with iCloud
- Handle errors gracefully (permissions, calendar access, etc.)

### Adding Localization
1. Add new language to localization files in `Resources/`
2. Update language list in README.md
3. Follow the guide in `docs/adding-new-languages.md`
4. Test all UI strings render correctly

### Updating UI
- Views are in `reminders-menubar/Views/`
- Use SwiftUI native components
- Respect system color schemes via `RmbColorScheme`
- Test with different macOS versions (minimum: Big Sur 11.0)

## Testing Considerations

### Manual Testing Checklist
- [ ] Create reminder with natural language date
- [ ] Edit existing reminder
- [ ] Mark reminder as complete/incomplete
- [ ] Move reminder between lists
- [ ] Delete reminder
- [ ] Filter by list
- [ ] Filter by time interval (today, week, etc.)
- [ ] Test keyboard shortcuts
- [ ] Verify iCloud sync
- [ ] Test permission request flow
- [ ] Check light/dark mode appearance
- [ ] Verify all localizations display correctly

### Edge Cases
- No reminders permission granted
- No reminder lists available
- iCloud sync disabled
- Very long reminder titles/notes
- Past due reminders
- Reminders with no due date
- Empty reminder lists

## Build and Run

This is an Xcode project. To build:
1. Open `reminders-menubar.xcodeproj` in Xcode
2. Select target device/simulator
3. Build and run (⌘R)

**Note**: Running on actual macOS hardware is recommended for proper EventKit testing, as permissions and iCloud sync work better on real devices.

## Distribution

- Distributed via Homebrew Cask: `brew install --cask reminders-menubar`
- Direct downloads available from GitHub Releases
- Code signing required for distribution outside Mac App Store

## Important Notes

### Security & Privacy
- This app accesses user's reminders via EventKit
- Requires explicit user permission (Privacy & Security settings)
- Data stays local or syncs via user's iCloud account
- No data sent to third-party servers

### macOS Compatibility
- Requires macOS Big Sur (11.0) or later
- Uses modern SwiftUI APIs
- Menu bar app lifecycle differs from standard macOS apps

### Known Limitations
- OpenCore Legacy Patcher users may need special configuration (see `docs/fix-for-opencore-legacy-patcher.md`)
- EventKit limitations apply (some reminder properties may not be accessible)

## Getting Help

- Check existing GitHub issues for similar problems
- Review Apple's EventKit documentation for reminder-related questions
- Consult SwiftUI documentation for UI-related questions
- See `.swiftlint.yml` for code style rules

## Recent Changes

See git commit history for recent changes. Notable recent work includes:
- Authorization alert message refactoring for clarity and localization
- Filipino localization added
- RmbReminder model improvements
- Version 1.25.0 updates

---

**Last Updated**: 2026-01-22
**Version**: 1.25.0
