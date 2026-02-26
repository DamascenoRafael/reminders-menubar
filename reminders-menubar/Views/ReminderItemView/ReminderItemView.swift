import SwiftUI
import EventKit

@MainActor
struct ReminderItemView: View {
    var reminderItem: ReminderItem
    var isShowingCompleted: Bool
    var showCalendarTitleOnDueDate = false
    @State var reminderItemIsHovered = false

    @State private var showingEditPopover = false
    @State private var isEditingTitle = false

    @Environment(\.searchFilterWords) private var searchFilterWords

    @State private var showingRemoveAlert = false

    var body: some View {
        if reminderItem.reminder.calendar == nil {
            // On macOS 12 the calendar may be nil during delete operation.
            // Returning Empty to avoid issues since calendar is a force unwrap.
            EmptyView()
        } else {
            mainReminderItemView()
        }
    }

    private var searchMatchOpacity: Double {
        guard !searchFilterWords.isEmpty else {
            return 1.0
        }
        if titleMatchesSearch(reminderItem.reminder.title) {
            return 1.0
        }
        if anyChildMatches(reminderItem) {
            return 0.4
        }
        return 0.3
    }

    private var matchesSearch: Bool {
        searchMatchOpacity > 0.5
    }

    private func titleMatchesSearch(_ title: String) -> Bool {
        let titleLower = title.lowercased()
        return searchFilterWords.allSatisfy { titleLower.contains($0) }
    }

    private func anyChildMatches(_ item: ReminderItem) -> Bool {
        let children = item.childReminders.uncompleted + item.childReminders.completed
        return children.contains { child in
            titleMatchesSearch(child.reminder.title) || anyChildMatches(child)
        }
    }

    @ViewBuilder
    func mainReminderItemView() -> some View {
        HStack(alignment: .top) {
            ReminderCompleteButton(reminderItem: reminderItem)

            VStack(spacing: 6) {
                HStack(spacing: 4) {
                    if let prioritySystemImage = reminderItem.reminder.ekPriority.systemImage {
                        Image(systemName: prioritySystemImage)
                            .foregroundColor(Color(reminderItem.reminder.calendar.color))
                    }
                    highlightedTitleText()
                        .fixedSize(horizontal: false, vertical: true)
                        .onTapGesture {
                            isEditingTitle = true
                            showingEditPopover = true
                        }

                    Spacer()

                    // TODO: remove the `.id` modifier while keeping properties updated (such as selected priority)
                    ReminderEllipsisMenuView(
                        showingEditPopover: $showingEditPopover,
                        showingRemoveAlert: $showingRemoveAlert,
                        reminder: reminderItem.reminder,
                        reminderHasChildren: reminderItem.hasChildren
                    )
                    .id(UUID())
                    .opacity(shouldShowEllipsisButton() ? 1 : 0)
                    .popover(isPresented: $showingEditPopover, arrowEdge: .trailing) {
                        ReminderEditPopover(
                            isPresented: $showingEditPopover,
                            focusOnTitle: $isEditingTitle,
                            reminder: reminderItem.reminder,
                            reminderHasChildren: reminderItem.hasChildren
                        )
                    }
                }
                .alert(isPresented: $showingRemoveAlert) {
                    removeReminderAlert()
                }

                if let dateDescription = reminderItem.reminder.relativeDateDescription {
                    ReminderDateDescriptionView(
                        dateDescription: dateDescription,
                        isExpired: reminderItem.reminder.isExpired,
                        hasRecurrenceRules: reminderItem.reminder.hasRecurrenceRules,
                        recurrenceRules: reminderItem.reminder.recurrenceRules,
                        calendarTitle: reminderItem.reminder.calendar.title,
                        showCalendarTitleOnDueDate: showCalendarTitleOnDueDate
                    )
                }

                if reminderItem.reminder.attachedUrl != nil || reminderItem.reminder.mailUrl != nil {
                    ReminderExternalLinksView(
                        attachedUrl: reminderItem.reminder.attachedUrl,
                        mailUrl: reminderItem.reminder.mailUrl
                    )
                }

                Divider()
            }
        }
        .onHover { isHovered in
            reminderItemIsHovered = isHovered
        }
        .padding(.leading, reminderItem.isChild ? 24 : 0)
        .opacity(searchMatchOpacity)
        .animation(.easeOut(duration: 0.2), value: searchMatchOpacity)

        ForEach(reminderItem.childReminders.uncompleted) { reminderItem in
            ReminderItemView(reminderItem: reminderItem, isShowingCompleted: isShowingCompleted)
        }

        if isShowingCompleted {
            ForEach(reminderItem.childReminders.completed) { reminderItem in
                ReminderItemView(reminderItem: reminderItem, isShowingCompleted: isShowingCompleted)
            }
        }
    }

    func shouldShowEllipsisButton() -> Bool {
        return reminderItemIsHovered || showingEditPopover
    }

    @ViewBuilder
    func highlightedTitleText() -> some View {
        let title = reminderItem.reminder.title ?? ""
        if searchFilterWords.isEmpty || !matchesSearch {
            Text(LocalizedStringKey(title.toDetectedLinkAttributedString()))
        } else {
            buildHighlightedText(title: title, words: searchFilterWords)
        }
    }

    // swiftlint:disable shorthand_operator
    private func buildHighlightedText(title: String, words: [String]) -> Text {
        let titleLower = title.lowercased()
        var boldRanges: [Range<String.Index>] = []

        for word in words {
            var searchStart = titleLower.startIndex
            while searchStart < titleLower.endIndex,
                  let range = titleLower.range(of: word, range: searchStart..<titleLower.endIndex) {
                let startOffset = titleLower.distance(from: titleLower.startIndex, to: range.lowerBound)
                let endOffset = titleLower.distance(from: titleLower.startIndex, to: range.upperBound)
                let originalStart = title.index(title.startIndex, offsetBy: startOffset)
                let originalEnd = title.index(title.startIndex, offsetBy: endOffset)
                boldRanges.append(originalStart..<originalEnd)
                searchStart = range.upperBound
            }
        }

        boldRanges.sort { $0.lowerBound < $1.lowerBound }

        let calendarColor = Color(reminderItem.reminder.calendar.color)
        var result = Text("")
        var currentIndex = title.startIndex

        for range in boldRanges {
            if currentIndex < range.lowerBound {
                result = result + Text(title[currentIndex..<range.lowerBound])
                    .foregroundColor(.primary.opacity(0.6))
            }
            let boldStart = max(currentIndex, range.lowerBound)
            if boldStart < range.upperBound {
                result = result + Text(title[boldStart..<range.upperBound])
                    .bold()
                    .underline(color: calendarColor)
            }
            currentIndex = range.upperBound
        }

        if currentIndex < title.endIndex {
            result = result + Text(title[currentIndex..<title.endIndex])
                .foregroundColor(.primary.opacity(0.6))
        }

        return result
    }
    // swiftlint:enable shorthand_operator

    func copyReminderToClipboard() {
        ReminderCopyService.copyReminder(reminderItem.reminder)

        hideCopiedToastWorkItem?.cancel()

        withAnimation(.easeInOut(duration: 0.2)) {
            showingCopiedToast = true
        }

        let workItem = DispatchWorkItem {
            withAnimation(.easeInOut(duration: 0.3)) {
                showingCopiedToast = false
            }
        }
        hideCopiedToastWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: workItem)
    }

    @ViewBuilder
    func copiedToastOverlay() -> some View {
        if showingCopiedToast {
            let expandLeading: CGFloat = 3
            let contractBottom: CGFloat = 2
            let cornerRadius: CGFloat = 10

            GeometryReader { proxy in
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Color.black.opacity(0.45))
                        .frame(
                            width: proxy.size.width + expandLeading,
                            height: proxy.size.height - contractBottom
                        )
                        .offset(x: -expandLeading, y: 0)

                    Text(rmbLocalized(.copiedToastMessage))
                        .font(.system(.headline, design: .rounded).weight(.semibold))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.25), radius: 6, x: 0, y: 2)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .transition(.opacity)
            .allowsHitTesting(false)
        }
    }

    func updateCopyEventMonitor(isHovered: Bool) {
        if isHovered {
            guard copyEventMonitor == nil else { return }

            copyEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                guard shouldHandleCopyShortcut(for: event) else { return event }

                copyReminderToClipboard()
                return nil
            }
        } else {
            removeCopyEventMonitor()
        }
    }

    func shouldHandleCopyShortcut(for event: NSEvent) -> Bool {
        guard reminderItemIsHovered else { return false }
        guard !showingEditPopover, !isEditingTitle else { return false }

        guard event.modifierFlags.contains(.command) else { return false }
        return event.charactersIgnoringModifiers?.lowercased() == "c"
    }

    func removeCopyEventMonitor() {
        if let monitor = copyEventMonitor {
            NSEvent.removeMonitor(monitor)
            copyEventMonitor = nil
        }
    }

    func removeReminderAlert() -> Alert {
        Alert(
            title: Text(rmbLocalized(.removeReminderAlertTitle)),
            message: Text(rmbLocalized(.removeReminderAlertMessage, arguments: reminderItem.reminder.title)),
            primaryButton: .destructive(Text(rmbLocalized(.removeReminderAlertConfirmButton)), action: {
                RemindersService.shared.remove(reminder: reminderItem.reminder)
            }),
            secondaryButton: .cancel(Text(rmbLocalized(.removeReminderAlertCancelButton)))
        )
    }
}

#Preview {
    var reminder: EKReminder {
        let calendar = EKCalendar(for: .reminder, eventStore: .init())
        calendar.color = .systemTeal

        let reminder = EKReminder(eventStore: .init())
        reminder.title = "Look for awesome projects on GitHub"
        reminder.isCompleted = false
        reminder.calendar = calendar

        return reminder
    }
    let reminderItem = ReminderItem(for: reminder)

    ReminderItemView(reminderItem: reminderItem, isShowingCompleted: false)
}
