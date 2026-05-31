import SwiftUI
import EventKit

struct ReminderEditView: View {
    enum Mode {
        case create
        case edit(EKReminder, reminderHasChildren: Bool)
    }

    @EnvironmentObject var remindersData: RemindersData
    @ObservedObject var userPreferences = UserPreferences.shared

    @Binding var isPresented: Bool

    let mode: Mode
    @State var rmbReminder: RmbReminder

    @State var titleTextFieldFocusTrigger = UUID()
    @State var titleTextFieldDynamicHeight: CGFloat = 0
    @State var notesTextFieldDynamicHeight: CGFloat = 0

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

    private var hasExternalLinks: Bool {
        guard case .edit(let reminder, _) = mode else { return false }
        return reminder.attachedUrl != nil || reminder.mailUrl != nil
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

            ReminderDateTimeEditView(date: $rmbReminder.date, components: .date, hasComponent: $rmbReminder.hasDueDate)
            ReminderDateTimeEditView(date: $rmbReminder.date, components: .time, hasComponent: $rmbReminder.hasTime)

            ReminderRecurrenceEditView(recurrence: $rmbReminder.recurrence, isEnabled: rmbReminder.hasDueDate)

            Divider()

            ReminderPriorityEditView(priority: $rmbReminder.priority)

            if #available(macOS 12, *) {
                Divider()
                ReminderTagsEditView(
                    tagNames: rmbReminder.tags.map(\.name),
                    onCommitTag: { rmbReminder.addTag(named: $0) },
                    onCommitEmpty: { confirmAction() },
                    onRemoveTag: { rmbReminder.removeTag(named: $0) },
                    onRemoveLastTag: { rmbReminder.removeLastTag() }
                )
            }

            if !reminderHasChildren {
                Divider()
                ReminderListEditView(selection: calendarPickerSelection)
            }

            if case .edit(let reminder, _) = mode, hasExternalLinks {
                Divider()
                externalLinksSection(reminder: reminder)
            }

            Spacer()

            actionButtons()
        }
        .frame(width: 300, alignment: .top)
        .frame(minHeight: hasExternalLinks ? 410 : 360)
        .fixedSize(horizontal: false, vertical: true)
        .padding()
        .modifier(RmbBackgroundModifier())
        .onAppear {
            if case .create = mode {
                rmbReminder.calendar = remindersData.calendarForSaving
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
                    Image(systemName: "xmark")
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
            focusTrigger: $titleTextFieldFocusTrigger
        )
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
            allowNewLineAndTab: true
        )
        .onSubmit { confirmAction() }
        .frame(height: notesTextFieldDynamicHeight)
    }

    // MARK: - External Links

    @ViewBuilder
    private func externalLinksSection(reminder: EKReminder) -> some View {
        HStack(alignment: .top) {
            Image(systemName: "link")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 6) {
                Text(rmbLocalized(.editReminderExternalLinksViewOnlyLabel))
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)

                ReminderExternalLinksView(
                    attachedUrl: reminder.attachedUrl,
                    mailUrl: reminder.mailUrl,
                    isCompact: false
                )
            }
        }
    }

    // MARK: - List

    private var calendarPickerSelection: Binding<EKCalendar?> {
        Binding(
            get: { getCalendarForSaving() },
            set: { newCalendar in
                guard let newCalendar else { return }
                rmbReminder.calendar = newCalendar
                let parsedCalendarIdentifier = rmbReminder.textCalendarResult.calendar?.calendarIdentifier
                if newCalendar.calendarIdentifier != parsedCalendarIdentifier {
                    // NOTE: Clear textCalendarResult because user overwrote the calendar.
                    rmbReminder.textCalendarResult = CalendarParser.TextCalendarResult()
                }
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

            let isSaveDisabled = finalNewReminderTitle().isEmpty
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
            Image(systemName: "trash")
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
                Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
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

    private func getCalendarForSaving() -> EKCalendar? {
        rmbReminder.textCalendarResult.calendar ?? rmbReminder.calendar
    }

    private func confirmAction() {
        let trimmedTitle = finalNewReminderTitle()
        guard !trimmedTitle.isEmpty,
              let calendar = getCalendarForSaving() else {
            return
        }

        rmbReminder.prepareToSave()
        rmbReminder.title = trimmedTitle
        rmbReminder.calendar = calendar

        if case .create = mode {
            RemindersService.shared.createNew(with: rmbReminder, in: calendar)
            remindersData.calendarForSaving = calendar
        } else if case .edit(let ekReminder, _) = mode {
            ekReminder.update(with: rmbReminder)
            if ekReminder.hasChanges || rmbReminder.hasTagChanges {
                RemindersService.shared.save(reminder: ekReminder, tags: rmbReminder.tags)
            }
        }

        isPresented = false
    }

    private func finalNewReminderTitle() -> String {
        var title = rmbReminder.title
        if let parsedPriorityRange = Range(rmbReminder.textPriorityResult.highlightedText.range, in: title) {
            title.replaceSubrange(parsedPriorityRange, with: "")
        }
        if userPreferences.removeParsedDateFromTitle {
            title = title.replacingOccurrences(of: rmbReminder.textDateResult.string, with: "")
        }
        title = title.replacingOccurrences(of: rmbReminder.textCalendarResult.string, with: "")
        for tagResult in rmbReminder.textTagResults.sorted(by: { $0.string.count > $1.string.count }) {
            title = title.replacingOccurrences(of: tagResult.string, with: "")
        }
        return title.trimmingCharacters(in: .whitespaces)
    }
}

#Preview("Create mode") {
    ReminderEditView(
        isPresented: .constant(true)
    )
    .environmentObject(RemindersData())
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
}
