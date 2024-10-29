import SwiftUI
import EventKit

@MainActor
struct ReminderItemView: View {
    @EnvironmentObject var remindersData: RemindersData
    
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
                    if let prioritySystemImage = item.reminder.prioritySystemImage {
                        Image(systemName: prioritySystemImage)
                            .foregroundColor(Color(item.reminder.calendar.color))
                    }
                    LinkText(
                        text: item.reminder.title,
                        onTitleTap: {
                            isEditingTitle = true
                            showingEditPopover = true
                        }
                    )
                    Spacer()
                    MenuButton(label:
                        Image(systemName: "ellipsis")
                    ) {
                        Button(action: {
                            showingEditPopover = true
                        }) {
                            HStack {
                                Image(systemName: "pencil")
                                Text(rmbLocalized(.editReminderOptionButton))
                            }
                        }
                        
                        // TODO: remove the `.id` modifier while keeping updated the selected priority
                        ChangePriorityOptionMenu(reminder: item.reminder).id(UUID())
                        
                        let otherCalendars = remindersData.calendars.filter {
                            $0.calendarIdentifier != item.reminder.calendar.calendarIdentifier
                        }
                        if !otherCalendars.isEmpty && !item.hasChildren {
                            MoveToOptionMenu(reminder: item.reminder, availableCalendars: otherCalendars)
                        }
                        
                        VStack {
                            Divider()
                        }
                        
                        Button(action: {
                            showingRemoveAlert = true
                        }) {
                            HStack {
                                Image(systemName: "minus.circle")
                                Text(rmbLocalized(.removeReminderOptionButton))
                            }
                        }
                    }
                    .menuButtonStyle(BorderlessButtonMenuButtonStyle())
                    .frame(width: 16, height: 16)
                    .padding(.top, 1)
                    .padding(.trailing, 10)
                    .help(rmbLocalized(.remindersOptionsButtonHelp))
                    .opacity(shouldShowEllipsisButton() ? 1 : 0)
                    .popover(isPresented: $showingEditPopover, arrowEdge: .trailing) {
                        ReminderEditPopover(isPresented: $showingEditPopover,
                                            focusOnTitle: $isEditingTitle,
                                            reminder: item.reminder)
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
    
    private struct LinkText: View {
        let text: String
        let onTitleTap: () -> Void
        
        var body: some View {
            let attributedString = attributedStringFromTitle(text)
            
            Text(LocalizedStringKey(attributedString.string))
                .fixedSize(horizontal: false, vertical: true)
                .gesture(
                    TapGesture()
                        .onEnded { _ in
                            if let event = NSApp.currentEvent, !event.modifierFlags.contains(.command) {
                                onTitleTap()
                            }
                        }
                )
        }
        
        private func attributedStringFromTitle(_ title: String) -> NSAttributedString {
            let attributedString = NSMutableAttributedString(string: title)
            
            // Detect URLs in the text
            let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
            let range = NSRange(location: 0, length: title.utf16.count)
            
            if let detector = detector {
                let matches = detector.matches(in: title, options: [], range: range)
                
                for match in matches {
                    if let url = match.url {
                        attributedString.addAttribute(.link, value: url, range: match.range)
                        attributedString.addAttribute(.foregroundColor, value: NSColor.linkColor, range: match.range)
                        attributedString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: match.range)
                        
                        // Add a gesture recognizer for this URL range
                        let tapGesture = NSClickGestureRecognizer(target: NSWorkspace.shared, action: #selector(NSWorkspace.open(_:)))
                        tapGesture.target = url as NSURL
                    }
                }
            }
            
            return attributedString
        }
    }
    
    func shouldShowEllipsisButton() -> Bool {
        return reminderItemIsHovered || showingEditPopover
    }
    
    func removeReminderAlert() -> Alert {
        Alert(title: Text(rmbLocalized(.removeReminderAlertTitle)),
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

@MainActor
struct ChangePriorityOptionMenu: View {
    var reminder: EKReminder
    
    @ViewBuilder
    func changePriorityButton(_ priority: EKReminderPriority, text: String) -> some View {
        let isSelected = priority == reminder.ekPriority
        Button(action: {
            reminder.ekPriority = priority
            RemindersService.shared.save(reminder: reminder)
        }) {
            SelectableView(title: text, isSelected: isSelected)
        }
    }
    
    var body: some View {
        MenuButton(label:
            HStack {
                Image(systemName: "exclamationmark.circle")
                Text(rmbLocalized(.changeReminderPriorityMenuOption))
            }
        ) {
            changePriorityButton(.low, text: rmbLocalized(.editReminderPriorityLowOption))
            changePriorityButton(.medium, text: rmbLocalized(.editReminderPriorityMediumOption))
            changePriorityButton(.high, text: rmbLocalized(.editReminderPriorityHighOption))
            Divider()
            changePriorityButton(.none, text: rmbLocalized(.editReminderPriorityNoneOption))
        }
    }
}

struct MoveToOptionMenu: View {
    var reminder: EKReminder
    var availableCalendars: [EKCalendar]
    
    var body: some View {
        MenuButton(label:
            HStack {
                Image(systemName: "folder")
                Text(rmbLocalized(.reminderMoveToMenuOption))
            }
        ) {
            ForEach(availableCalendars, id: \.calendarIdentifier) { calendar in
                // TODO: Fix the warning from Xcode when editing the reminder calendar:
                // [utility] You are about to trigger decoding the resolution token map from JSON data.
                // This is probably not what you want for performance to trigger it from -isEqual:,
                // unless you are running Tests then it's fine
                // {class: REMAccountStorage, self-map: (null), other-map: (null)}
                Button(action: {
                    reminder.calendar = calendar
                    RemindersService.shared.save(reminder: reminder)
                }) {
                    SelectableView(title: calendar.title, color: Color(calendar.color))
                }
            }
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
                    .environmentObject(RemindersData())
                    .colorScheme(color)
                    .previewDisplayName("\(color) mode")
            }
        }
    }
}
