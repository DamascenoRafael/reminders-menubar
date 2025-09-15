Reminders Notes Format for BOB

Goal
- Preserve user-authored notes while storing structured metadata for sync.

Format
- Original user notes (free text)
- Separator line
- BOB metadata block

Example
User’s existing notes remain here.
-----------------
Task: TK-ABC123
Story: S-42
Goal: G-9
Theme: Theme-7
Created: 2025-09-14 14:31
Updated: 2025-09-15 09:00
Due: 2025-09-15
Last comment: Ready for review

Parser
- `NotesCodec.parse(notes)` extracts: `ref`, `storyId`, `goalId`, `theme`, `createdAt`, `updatedAt`, `dueDate`, `lastComment`, and returns `userNotes` (text above the separator).

Writer
- `NotesCodec.format(meta, existing)` builds the header and reattaches `existing` after the separator.
