# CLAUDE.md

## Project Overview

Reminders MenuBar is a macOS menu bar application that provides quick access to Apple Reminders. It syncs with Apple Reminders and iCloud, allowing users to view, create, and manage reminders without opening the full Reminders app.

**Key Features:** Menu bar integration, natural language date parsing, reminder CRUD operations, list filtering, keyboard shortcuts, 18+ language support.

## Build Commands

```bash
# Open in Xcode
open reminders-menubar.xcodeproj

# Build from command line
xcodebuild -project reminders-menubar.xcodeproj -scheme reminders-menubar -configuration Release

# Run SwiftLint
swiftlint lint --config .swiftlint.yml

# Archive for distribution
xcodebuild -project reminders-menubar.xcodeproj -scheme reminders-menubar -configuration Release -archivePath build/reminders-menubar.xcarchive archive
```

## Project Structure

```
reminders-menubar/
├── Models/              # Data models (RemindersData, RmbReminder, ReminderItem, etc.)
├── Services/            # Business logic (RemindersService, UserPreferences, parsers)
├── Views/               # SwiftUI views organized by feature
├── Extensions/          # Swift type extensions
├── Resources/           # Assets, colors, localizations (Localizable.xcstrings)
├── AppDelegate.swift    # Menu bar setup and lifecycle
└── Constants.swift      # App configuration
reminders-menubar-launcher/  # Helper app for launch-at-login
```

## Key Technologies

- **SwiftUI** - Declarative UI (macOS 11+)
- **Combine** - Reactive data binding
- **EventKit** - Apple Reminders access via EKEventStore
- **AppKit** - Menu bar integration (NSStatusBar, NSPanel)
- **KeyboardShortcuts** - Third-party library for keyboard shortcuts

## Window Behavior

The app uses a borderless floating NSPanel instead of NSPopover:
- **Draggable** - Click and drag anywhere on the window background
- **Resizable** - Default 340x460, minimum 280x300
- **Floating** - Always stays on top of other windows when visible
- **Transparent** - 10% transparency when mouse is not hovering
- **Responsive** - Content scales down for narrow widths (< 300px)
- **Position persists** - Window frame saved in UserPreferences

## Architecture Patterns

- **MVVM** with ObservableObject/Published for reactive updates
- **Singleton services** - RemindersService.shared, UserPreferences.shared, DateParser.shared
- **@EnvironmentObject** - RemindersData passed through view hierarchy
- **@MainActor** - Thread-safe UI operations
- **Combine publishers** - Event-driven updates from EKEventStore changes

## Code Conventions

- SwiftLint enforced with 60+ rules (see `.swiftlint.yml`)
- Comments must have space after `//`
- No double spaces
- Attributes like `@objc`, `@Environment` on same line
- Prefer direct returns over intermediate variables
- YODA conditions allowed (e.g., `5 == count`)

## Important Files

- `reminders-menubar/Services/RemindersService.swift` - EventKit wrapper for reminder CRUD
- `reminders-menubar/Models/RemindersData.swift` - Main observable data controller
- `reminders-menubar/Services/UserPreferences.swift` - User settings persistence
- `reminders-menubar/Models/RmbReminder.swift` - Reminder creation with inline parsing
- `reminders-menubar/Views/ContentView.swift` - Main view container
- `reminders-menubar/Resources/Localizable.xcstrings` - All translations

## Inline Parsing Syntax

When creating reminders, users can use inline syntax:
- **Dates:** Natural language (e.g., "tomorrow 3pm", "next friday")
- **Calendar:** `@calendarname` or `/calendarname`
- **Priority:** `!` (high), `!!` (medium), `!!!` (low)

## Deployment

- **Minimum macOS:** Big Sur 11.0
- **Bundle ID:** br.com.damascenorafael.reminders-menubar
- **Distribution:** Homebrew (`brew install --cask reminders-menubar`) or GitHub releases
