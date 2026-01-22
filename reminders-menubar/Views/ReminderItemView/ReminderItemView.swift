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
                    Text(LocalizedStringKey(reminderItem.reminder.title.toDetectedLinkAttributedString()))
                        .lineLimit(1)
                        .truncationMode(.tail)
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
