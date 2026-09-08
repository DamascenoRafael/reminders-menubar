import SwiftUI
import EventKit

struct ReminderEditView: View {
    enum Mode {
        case create
        case edit(EKReminder, reminderHasChildren: Bool)
    }

    @EnvironmentObject var remindersData: RemindersData
    @EnvironmentObject var newReminderTypingCoordinator: NewReminderTypingCoordinator
    @ObservedObject var userPreferences = UserPreferences.shared

    @Binding var isPresented: Bool

    let mode: Mode
    @State var rmbReminder: RmbReminder

    @StateObject private var focusCoordinator = ReminderEditFocusCoordinator()
    @State var titleTextFieldDynamicHeight = NSLayoutManager().defaultLineHeight(
        for: .preferredFont(forTextStyle: .title3)
    )
    @State var notesTextFieldDynamicHeight = NSLayoutManager().defaultLineHeight(
        for: .systemFont(ofSize: NSFont.systemFontSize)
    )

    @State private var showingRemoveAlert = false
    @State private var removeButtonIsHovered = false
    @State private var cancelButtonIsHovered = false
    @State private var copyButtonIsHovered = false
    @State private var isCopied = false
    @State private var copiedDismissWork: DispatchWorkItem?

    private var reminderHasChildren: Bool {
        if case .edit(_, let hasChildren) = mode {
            return hasChildren
        }
        return false
    }

    private var externalLinks: ReminderExternalLinks {
        switch mode {
        case .create:
            return ReminderExternalLinks(draft: rmbReminder)
        case .edit(let reminder, _):
            return ReminderExternalLinks(reminder: reminder, draft: rmbReminder)
        }
    }

    init(isPresented: Binding<Bool>, reminder: EKReminder, reminderHasChildren: Bool) {
        self.mode = .edit(reminder, reminderHasChildren: reminderHasChildren)

        _isPresented = isPresented
        _rmbReminder = State(initialValue: RmbReminder(reminder: reminder))
    }

    init(isPresented: Binding<Bool>) {
        self.mode = .create

        _isPresented = isPresented
        _rmbReminder = State(initialValue: RmbReminder())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            cancelHeader()

            titleAndNotesSection()

            Divider()

            LazyVGrid(columns: [GridItem(), GridItem()], alignment: .leading) {
                ReminderDateTimeEditView(
                    date: dateBinding,
                    components: .date,
                    hasComponent: hasDueDateBinding
                )

                ReminderDateTimeEditView(
                    date: dateBinding,
                    components: .time,
                    hasComponent: hasTimeBinding
                )
            }

            ReminderRecurrenceEditView(recurrence: $rmbReminder.recurrence, isEnabled: rmbReminder.hasDueDate)

            Divider()

            ReminderFlagUrgentEditView(isFlagged: isFlaggedBinding, isUrgent: isUrgentBinding)

            ReminderPriorityEditView(priority: $rmbReminder.priority)

            if #available(macOS 12, *) {
                Divider()
                ReminderTagsEditView(
                    tagNames: rmbReminder.tags.map(\.name),
                    onCommitTag: { rmbReminder.addTag(named: $0) },
                    onCommitEmpty: { confirmAction() },
                    onRemoveTag: { rmbReminder.removeTag(named: $0) },
                    onRemoveLastTag: { rmbReminder.removeLastTag() },
                    focusTrigger: $focusCoordinator.tagsTrigger,
                    onMoveFocus: { focusCoordinator.moveFocus(from: .tags, direction: $0) }
                )
            }

            if !reminderHasChildren {
                Divider()
                ReminderListEditView(selection: calendarPickerSelection)
            }

            Divider()
            externalLinksSection(externalLinks)

            Spacer()

            actionButtons()
        }
        .frame(width: 300, alignment: .top)
        .frame(minHeight: 410)
        .fixedSize(horizontal: false, vertical: true)
        .padding()
        .modifier(RmbBackgroundModifier())
        .onAppear {
            if case .create = mode {
                if let calendar = remindersData.calendarForSaving {
                    rmbReminder.userDidSetCalendar(calendar)
                }
                if userPreferences.autoSuggestToday {
                    rmbReminder.setIsAutoSuggestingTodayForCreation()
                }
            }
        }
    }

    // MARK: - Cancel

    @ViewBuilder
    private func cancelHeader() -> some View {
        HStack {
            Spacer()

            Button {
                isPresented = false
            } label: {
                HStack {
                    Image(rmbSymbol: .xmark)
                        .font(.system(size: 8, weight: .medium))
                    Text(String("esc"))
                        .font(.caption)
                }
                .foregroundColor(.secondary)
                .padding(4)
            }
            .buttonStyle(.borderless)
            .background(
                cancelButtonIsHovered
                ? Color.rmbColor(.buttonHover)
                : Color.rmbColor(.buttonHover).opacity(0.2)
            )
            .cornerRadius(4)
            .onHover { hovering in
                cancelButtonIsHovered = hovering
            }
            .keyboardShortcut(.cancelAction)
        }
    }

    // MARK: - Title & Notes

    @ViewBuilder
    private func titleAndNotesSection() -> some View {
        RmbHighlightedTextField(
            placeholder: rmbLocalized(.editReminderTitleTextFieldPlaceholder),
            text: $rmbReminder.title,
            highlightedTexts: rmbReminder.highlightedTexts,
            textContainerDynamicHeight: $titleTextFieldDynamicHeight,
            focusTrigger: $focusCoordinator.titleTrigger
        )
        .onDidBecomeFirstResponder { textView in
            newReminderTypingCoordinator.replayPendingEvents(in: textView)
        }
        .onMoveFocus { focusCoordinator.moveFocus(from: .title, direction: $0) }
        .onSubmit { confirmAction() }
        .autoComplete(
            isInitialCharValid: { char in
                if #available(macOS 12, *) {
                    CalendarParser.isInitialCharValid(char) || TagParser.isInitialCharValid(char)
                } else {
                    CalendarParser.isInitialCharValid(char)
                }
            },
            suggestions: { initialChar, typingWord in
                if #available(macOS 12, *), TagParser.isInitialCharValid(initialChar) {
                    return TagParser.autoCompleteSuggestions(typingWord)
                }
                return CalendarParser.autoCompleteSuggestions(typingWord)
            }
        )
        .fontStyle(.title3)
        .frame(height: titleTextFieldDynamicHeight)

        RmbHighlightedTextField(
            placeholder: rmbLocalized(.editReminderNotesTextFieldPlaceholder),
            text: Binding($rmbReminder.notes, replacingNilWith: ""),
            textContainerDynamicHeight: $notesTextFieldDynamicHeight,
            allowsLineBreaks: true,
            focusTrigger: $focusCoordinator.notesTrigger
        )
        .onMoveFocus { focusCoordinator.moveFocus(from: .notes, direction: $0) }
        .onSubmit { confirmAction() }
        .frame(height: notesTextFieldDynamicHeight)
    }

    // MARK: - External Links

    @ViewBuilder
    private func externalLinksSection(_ externalLinks: ReminderExternalLinks) -> some View {
        HStack(alignment: .top) {
            Image(rmbSymbol: .link)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 6) {
                Text(rmbLocalized(.editReminderExternalLinksViewOnlyLabel))
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)

                if externalLinks.isEmpty {
                    Text(rmbLocalized(.editReminderExternalLinksEmptyMessage))
                        .font(.footnote)
                        .foregroundColor(.secondary)
                } else {
                    ReminderExternalLinksView(
                        externalLinks: externalLinks,
                        isCompact: false
                    )
                }
            }
        }
    }

    // MARK: - Date/Time/Urgent Bindings

    private var dateBinding: Binding<Date> {
        Binding(
            get: { rmbReminder.date },
            set: { rmbReminder.userDidSetDate($0) }
        )
    }

    private var hasDueDateBinding: Binding<Bool> {
        Binding(
            get: { rmbReminder.hasDueDate },
            set: { rmbReminder.userDidSetHasDueDate($0) }
        )
    }

    private var hasTimeBinding: Binding<Bool> {
        Binding(
            get: { rmbReminder.hasTime },
            set: { rmbReminder.userDidSetHasTime($0) }
        )
    }

    private var isUrgentBinding: Binding<Bool> {
        Binding(
            get: { rmbReminder.isUrgent },
            set: { rmbReminder.userDidSetIsUrgent($0) }
        )
    }

    private var isFlaggedBinding: Binding<Bool> {
        Binding(
            get: { rmbReminder.isFlagged },
            set: { rmbReminder.userDidSetIsFlagged($0) }
        )
    }

    // MARK: - List

    private var calendarPickerSelection: Binding<EKCalendar?> {
        Binding(
            get: { rmbReminder.calendar },
            set: { newCalendar in
                guard let newCalendar else { return }
                rmbReminder.userDidSetCalendar(newCalendar)
            }
        )
    }

    // MARK: - Actions

    @ViewBuilder
    private func actionButtons() -> some View {
        HStack(spacing: 12) {
            if case .edit(let ekReminder, _) = mode {
                editActionButtons(for: ekReminder)
            }

            Spacer()

            let isSaveDisabled = rmbReminder.titleRemovingParsedTokens().isEmpty
            Button {
                confirmAction()
            } label: {
                HStack {
                    Text(rmbLocalized(.reminderEditPopoverSaveButton))
                    Text(String("⏎"))
                        .font(.footnote)
                }
                .padding(4)
                .padding(.horizontal, 4)
            }
            .modifier(ConfirmButtonModifier())
            .disabled(isSaveDisabled)
            .keyboardShortcut(.return, modifiers: [])
        }
    }

    @ViewBuilder
    private func editActionButtons(for ekReminder: EKReminder) -> some View {
        Button {
            showingRemoveAlert = true
        } label: {
            Image(rmbSymbol: .trash)
                .foregroundColor(removeButtonIsHovered ? .rmbColor(.destructiveAction) : .secondary)
                .frame(width: 24, height: 24)
        }
        .buttonStyle(.borderless)
        .background(removeButtonIsHovered ? Color.rmbColor(.buttonHover) : nil)
        .cornerRadius(8)
        .onHover { hovering in
            removeButtonIsHovered = hovering
        }
        .alert(isPresented: $showingRemoveAlert) {
            removeReminderAlert(for: ekReminder) {
                isPresented = false
            }
        }

        Button {
            ReminderCopyService.copyReminder(ekReminder)
            isCopied = true
            copiedDismissWork?.cancel()
            let work = DispatchWorkItem { isCopied = false }
            copiedDismissWork = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: work)
        } label: {
            HStack(spacing: 4) {
                Image(rmbSymbol: isCopied ? .checkmark : .docOnDoc)
                    .frame(width: 24, height: 24)
                Text(isCopied ? rmbLocalized(.copiedToastMessage) : rmbLocalized(.copyReminderButton))
                    .padding(.trailing, 6)
            }
            .foregroundColor(
                isCopied
                ? .rmbColor(.successIndicator)
                : (copyButtonIsHovered ? .accentColor : .secondary)
            )
            .padding(.horizontal, 4)
        }
        .buttonStyle(.borderless)
        .background(copyButtonIsHovered ? Color.rmbColor(.buttonHover) : nil)
        .cornerRadius(8)
        .onHover { hovering in
            copyButtonIsHovered = hovering
        }
    }

    // MARK: - Helpers

    private func confirmAction() {
        let finalTitle = rmbReminder.titleRemovingParsedTokens()
        guard !finalTitle.isEmpty,
              let calendar = rmbReminder.calendar else {
            return
        }

        rmbReminder.prepareToSave()
        rmbReminder.title = finalTitle

        if case .create = mode {
            RemindersService.shared.createNew(with: rmbReminder, in: calendar)
            remindersData.calendarForSaving = calendar
            if userPreferences.closePopoverAfterCreatingReminder {
                AppDelegate.shared.popover.performClose(nil)
            }
        } else if case .edit(let ekReminder, _) = mode {
            ekReminder.update(with: rmbReminder)
            if ekReminder.hasChanges || rmbReminder.hasPrivateApiChanges {
                RemindersService.shared.save(
                    reminder: ekReminder,
                    tags: rmbReminder.tags,
                    isFlagged: rmbReminder.isFlagged,
                    isUrgent: rmbReminder.isUrgent
                )
            }
        }

        isPresented = false
    }
}

#Preview("Create mode") {
    ReminderEditView(
        isPresented: .constant(true)
    )
    .environmentObject(RemindersData())
    .environmentObject(NewReminderTypingCoordinator())
}

#Preview("Edit mode") {
    var reminder: EKReminder {
        let calendar = EKCalendar(for: .reminder, eventStore: .init())
        calendar.color = .systemTeal

        let reminder = EKReminder(eventStore: .init())
        reminder.title = "Look for awesome projects on GitHub"
        reminder.isCompleted = false
        reminder.calendar = calendar
        reminder.dueDateComponents = Date().dateComponents(withTime: true)
        reminder.ekPriority = .high

        return reminder
    }

    ReminderEditView(
        isPresented: .constant(true),
        reminder: reminder,
        reminderHasChildren: false
    )
    .environmentObject(RemindersData())
    .environmentObject(NewReminderTypingCoordinator())
}

// MARK: - Focus Coordinator

private final class ReminderEditFocusCoordinator: ObservableObject {
    enum Field: Equatable {
        case title
        case notes
        case tags
    }

    @Published var titleTrigger: UUID? = UUID()
    @Published var notesTrigger: UUID?
    @Published var tagsTrigger: UUID?

    private var fieldOrder: [Field] {
        if #available(macOS 12, *) {
            return [.title, .notes, .tags]
        } else {
            return [.title, .notes]
        }
    }

    func moveFocus(from field: Field, direction: FocusDirection) {
        guard let currentIndex = fieldOrder.firstIndex(of: field) else { return }
        let destinationIndex = (currentIndex + direction.offset + fieldOrder.count) % fieldOrder.count
        focus(fieldOrder[destinationIndex])
    }

    private func focus(_ field: Field) {
        switch field {
        case .title:
            titleTrigger = UUID()
        case .notes:
            notesTrigger = UUID()
        case .tags:
            tagsTrigger = UUID()
        }
    }
}
