import SwiftUI
import EventKit

@MainActor
struct ReminderItemView: View {
    @Environment(\.colorScheme) private var colorScheme

    var reminderItem: ReminderItem
    var isShowingCompleted: Bool
    var showCalendarTitleOnDueDate = false
    @State var reminderItemIsHovered = false

    @State private var showingEditPopover = false
    @State private var isEditingTitle = false

    @State private var showingRemoveAlert = false
    @State private var showingCopiedToast = false
    @State private var copyEventMonitor: Any?
    @State private var isPendingCompletion = false

    var body: some View {
        if reminderItem.reminder.calendar == nil {
            // On macOS 12 the calendar may be nil during delete operation.
            // Returning Empty to avoid issues since calendar is a force unwrap.
            EmptyView()
        } else {
            mainReminderItemView()
        }
    }

    @ViewBuilder
    func mainReminderItemView() -> some View {
        HStack(alignment: .top) {
            ReminderCompleteButton(reminderItem: reminderItem, isPendingCompletion: $isPendingCompletion)

            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    if let prioritySystemImage = reminderItem.reminder.ekPriority.systemImage {
                        Image(systemName: prioritySystemImage)
                            .foregroundColor(Color(reminderItem.reminder.calendar.color))
                    }
                    Text(LocalizedStringKey(reminderItem.reminder.title.toDetectedLinkAttributedString()))
                        .fixedSize(horizontal: false, vertical: true)
                        .onTapGesture {
                            guard !isPendingCompletion else { return }
                            isEditingTitle = true
                            showingEditPopover = true
                        }

                    Spacer()

                    // TODO: remove the `.id` modifier while keeping properties updated (such as selected priority)
                    ReminderEllipsisMenuView(
                        showingEditPopover: $showingEditPopover,
                        showingRemoveAlert: $showingRemoveAlert,
                        onCopyReminder: { copyReminderToClipboard() },
                        reminder: reminderItem.reminder,
                        reminderHasChildren: reminderItem.hasChildren
                    )
                    .id(UUID())
                    .opacity(shouldShowEllipsisButton() ? 1 : 0)
                    .allowsHitTesting(!isPendingCompletion)
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
                    .padding(.top, 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .opacity(isPendingCompletion || reminderItem.reminder.isCompleted ? 0.6 : 1.0)
            .animation(.easeInOut(duration: 0.3), value: isPendingCompletion)
            .overlay(
                copiedToastOverlay()
                    .opacity(showingCopiedToast ? 1 : 0)
                    .animation(.easeInOut(duration: 0.3), value: showingCopiedToast)
                    .onChange(of: showingCopiedToast) { isShowing in
                        guard isShowing else { return }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            showingCopiedToast = false
                        }
                    }
            )
        }
        .onHover { isHovered in
            reminderItemIsHovered = isHovered
            updateCopyEventMonitor(isHovered: isHovered)
        }
        .onChange(of: showingEditPopover) { isShowing in
            if isShowing {
                removeCopyEventMonitor()
            }
        }
        .onDisappear {
            removeCopyEventMonitor()
        }
        .padding(.bottom, 2)
        .padding(.leading, reminderItem.isChild ? 22 : 0)

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
        return !isPendingCompletion && (reminderItemIsHovered || showingEditPopover)
    }

    func copyReminderToClipboard() {
        ReminderCopyService.copyReminder(reminderItem.reminder)
        showingCopiedToast = true
    }

    @ViewBuilder
    func copiedToastOverlay() -> some View {
        GeometryReader { geometry in
            Text(rmbLocalized(.copiedToastMessage))
                .font(.system(.headline, design: .rounded).weight(.semibold))
                .foregroundColor(.primary)
                .padding(.horizontal, 32)
                .frame(maxHeight: min(32, geometry.size.height - 4))
                .background(
                    Capsule()
                        .fill(colorScheme == .light ? Color.white : Color.black)
                        .overlay(Capsule().stroke(Color.gray.opacity(0.2)))
                        .opacity(0.9)
                )
                .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .transition(.opacity)
        .allowsHitTesting(false)
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
        reminder.addDueDateAndAlarm(for: Date().addingTimeInterval(86_400), withTime: false)

        return reminder
    }
    let reminderItem = ReminderItem(for: reminder)

    ReminderItemView(reminderItem: reminderItem, isShowingCompleted: false)
}
