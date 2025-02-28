import SwiftUI
import EventKit

@MainActor
struct ReminderItemView: View {
    var item: ReminderItem
    var isShowingCompleted: Bool
    var showCalendarTitleOnDueDate = false
    @State var reminderItemIsHovered = false
    
    @State private var showingEditPopover = false
    @State private var isEditingTitle = false
    
    @State private var showingRemoveAlert = false
    
    var body: some View {
        HStack(alignment: .top) {
            Button(action: {
                item.reminder.isCompleted.toggle()
                RemindersService.shared.save(reminder: item.reminder)
                if item.reminder.isCompleted {
                    item.childReminders.uncompleted.forEach { uncompletedChild in
                        uncompletedChild.reminder.isCompleted = true
                        RemindersService.shared.save(reminder: uncompletedChild.reminder)
                    }
                }
            }) {
                Image(systemName: item.reminder.isCompleted ? "largecircle.fill.circle" : "circle")
                    .resizable()
                    .frame(width: 18, height: 18)
                    .padding(.top, 1)
                    .foregroundColor(Color(item.reminder.calendar.color))
            }.buttonStyle(PlainButtonStyle())
            VStack(spacing: 8) {
                HStack(spacing: 4) {
                    if let prioritySystemImage = item.reminder.ekPriority.systemImage {
                        Image(systemName: prioritySystemImage)
                            .foregroundColor(Color(item.reminder.calendar.color))
                    }
                    Text(LocalizedStringKey(item.reminder.title.toDetectedLinkAttributedString()))
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
                        reminder: item.reminder,
                        reminderHasChildren: item.hasChildren
                    )
                    .id(UUID())
                    .opacity(shouldShowEllipsisButton() ? 1 : 0)
                    .popover(isPresented: $showingEditPopover, arrowEdge: .trailing) {
                        ReminderEditPopover(
                            isPresented: $showingEditPopover,
                            focusOnTitle: $isEditingTitle,
                            reminder: item.reminder,
                            reminderHasChildren: item.hasChildren
                        )
                    }
                }
                .alert(isPresented: $showingRemoveAlert) {
                    removeReminderAlert()
                }
                
                if let dateDescription = item.reminder.relativeDateDescription {
                    HStack {
                        HStack {
                            Image(systemName: "calendar")
                            Text(dateDescription)
                                .foregroundColor(item.reminder.isExpired ? .red : nil)
                        }
                        .padding(.trailing, 5)
                        
                        if item.reminder.hasRecurrenceRules {
                            Image(systemName: "repeat")
                            let rule = item.reminder.recurrenceRules?.first
                            Text(recurrenceLabel(rule))
                        }
                        
                        if showCalendarTitleOnDueDate {
                            Spacer()
                            
                            Text(item.reminder.calendar.title)
                        }
                    }
                    .font(.footnote)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.trailing, 12)
                }
                
                if item.reminder.attachedUrl != nil || item.reminder.mailUrl != nil {
                    ExternalLinksView(attachedUrl: item.reminder.attachedUrl, mailUrl: item.reminder.mailUrl)
                }
                
                Divider()
            }
        }
        .onHover { isHovered in
            reminderItemIsHovered = isHovered
        }
        .padding(.leading, item.isChild ? 26 : 0)
        
        ForEach(item.childReminders.uncompleted) { reminderItem in
            ReminderItemView(item: reminderItem, isShowingCompleted: isShowingCompleted)
        }
        
        if isShowingCompleted {
            ForEach(item.childReminders.completed) { reminderItem in
                ReminderItemView(item: reminderItem, isShowingCompleted: isShowingCompleted)
            }
        }
    }
    
    func shouldShowEllipsisButton() -> Bool {
        return reminderItemIsHovered || showingEditPopover
    }
    
    func removeReminderAlert() -> Alert {
        Alert(
            title: Text(rmbLocalized(.removeReminderAlertTitle)),
            message: Text(rmbLocalized(.removeReminderAlertMessage, arguments: item.reminder.title)),
            primaryButton: .destructive(Text(rmbLocalized(.removeReminderAlertConfirmButton)), action: {
                RemindersService.shared.remove(reminder: item.reminder)
              }),
            secondaryButton: .cancel(Text(rmbLocalized(.removeReminderAlertCancelButton)))
        )
    }
    
    func recurrenceLabel(_ rule: EKRecurrenceRule?) -> String {
        let interval = rule?.interval ?? 1
        
        switch rule?.frequency {
        case .daily:
            return rmbLocalized(.reminderRecurrenceDailyLabel, arguments: interval)
        case .weekly:
            return rmbLocalized(.reminderRecurrenceWeeklyLabel, arguments: interval)
        case .monthly:
            return rmbLocalized(.reminderRecurrenceMonthlyLabel, arguments: interval)
        case .yearly:
            return rmbLocalized(.reminderRecurrenceYearlyLabel, arguments: interval)
        default:
            return ""
        }
    }
}

struct ExternalLinksView: View {
    var attachedUrl: URL?
    var mailUrl: URL?
    
    var body: some View {
        HStack {
            if let attachedUrl {
                Link(destination: attachedUrl) {
                    Image(systemName: "safari")
                    Text(attachedUrl.displayedUrl)
                }
                .modifier(ReminderExternalLinkStyle())
            }
            
            if let mailUrl {
                Link(destination: mailUrl) {
                    Image(systemName: "envelope")
                }
                .modifier(ReminderExternalLinkStyle())
            }
            
            Spacer()
        }
    }
}

struct ReminderExternalLinkStyle: ViewModifier {
    func body(content: Content) -> some View {
        return content
            .foregroundColor(.primary)
            .frame(height: 25)
            .padding(.horizontal, 8)
            .background(Color.secondary.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct ReminderItemView_Previews: PreviewProvider {
    static var reminder: EKReminder {
        let calendar = EKCalendar(for: .reminder, eventStore: .init())
        calendar.color = .systemTeal
        
        let reminder = EKReminder(eventStore: .init())
        reminder.title = "Look for awesome projects on GitHub"
        reminder.isCompleted = false
        reminder.calendar = calendar
        
        return reminder
    }
    
    static var reminderItem = ReminderItem(for: reminder)
    
    static var previews: some View {
        Group {
            ForEach(ColorScheme.allCases, id: \.self) { color in
                ReminderItemView(item: reminderItem, isShowingCompleted: false)
                    .colorScheme(color)
                    .previewDisplayName("\(color) mode")
            }
        }
    }
}
