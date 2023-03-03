import SwiftUI
import EventKit

struct ReminderItemView: View {
    @EnvironmentObject var remindersData: RemindersData
    
    var reminder: EKReminder
    var showCalendarTitleOnDueDate = false
    @State var reminderItemIsHovered = false
    
    @State private var showingEditPopover = false
    
    @State private var showingRemoveAlert = false
    @State private var hasBeenRemoved = false
    
    @State var stateReminder: EKReminder
    
    var body: some View {
        HStack(alignment: .top) {
            Button(action: {
                reminder.isCompleted.toggle()
                RemindersService.shared.save(reminder: reminder)
            }) {
                Image(systemName: reminder.isCompleted ? "largecircle.fill.circle" : "circle")
                    .resizable()
                    .frame(width: 18, height: 18)
                    .padding(.top, 1)
                    .foregroundColor(Color(reminder.calendar.color))
            }.buttonStyle(PlainButtonStyle())
            VStack(spacing: 8) {
                HStack(spacing: 4) {
                    if let prioritySystemImage = reminder.prioritySystemImage {
                        Image(systemName: prioritySystemImage)
                            .foregroundColor(Color(reminder.calendar.color))
                    }
                    TextEditor(text: $stateReminder.title)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 4.0)
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
                        
                        let otherCalendars = remindersData.calendars.filter {
                            $0.calendarIdentifier != reminder.calendar.calendarIdentifier
                        }
                        if !otherCalendars.isEmpty {
                            MoveToOptionMenu(reminder: reminder, availableCalendars: otherCalendars)
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
                        ReminderEditPopover(reminder: reminder)
                    }
                }
                .alert(isPresented: $showingRemoveAlert) {
                    removeReminderAlert()
                }
                .onChange(of: showingRemoveAlert) { isShowing in
                    AppDelegate.shared.changeBehaviorBasedOnModal(isShowing: isShowing)
                }
                
                if let dateDescription = reminder.relativeDateDescription {
                    HStack {
                        HStack {
                            Image(systemName: "calendar")
                            Text(dateDescription)
                                .foregroundColor(reminder.isExpired ? .red : nil)
                        }
                        .padding(.trailing, 5)
                        
                        if reminder.hasRecurrenceRules {
                            Image(systemName: "repeat")
                        }
                        
                        if showCalendarTitleOnDueDate {
                            Spacer()
                            
                            Text(reminder.calendar.title)
                        }
                    }
                    .font(.footnote)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.trailing, 12)
                }
                
                if let url = reminder.attachedUrl {
                    HStack {
                        Link(destination: url) {
                            Image(systemName: "safari")
                            Text(url.displayedUrl)
                        }
                        .foregroundColor(.primary)
                        .frame(height: 25)
                        .padding(.horizontal, 8)
                        .background(Color.secondary.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        
                        Spacer()
                    }
                }
                
                Divider()
            }
        }
        .onHover { isHovered in
            reminderItemIsHovered = isHovered
        }
        .onDisappear(perform: {
            AppDelegate.shared.changeBehaviorToDismissIfNeeded()
            if hasBeenRemoved {
                RemindersService.shared.commitChanges()
            }
        })
    }
    
    func shouldShowEllipsisButton() -> Bool {
        return reminderItemIsHovered || showingEditPopover
    }
    
    func removeReminderAlert() -> Alert {
        Alert(title: Text(rmbLocalized(.removeReminderAlertTitle)),
              message: Text(rmbLocalized(.removeReminderAlertMessage, arguments: reminder.title)),
              primaryButton: .destructive(Text(rmbLocalized(.removeReminderAlertConfirmButton)), action: {
                RemindersService.shared.remove(reminder: reminder)
                hasBeenRemoved = true
              }),
              secondaryButton: .cancel(Text(rmbLocalized(.removeReminderAlertCancelButton)))
        )
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
                    Group {
                        Text("●  ").foregroundColor(Color(calendar.color)) +
                        Text(calendar.title)
                    }
                }
            }
        }
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
    
    static var previews: some View {
        Group {
            ForEach(ColorScheme.allCases, id: \.self) { color in
                ReminderItemView(reminder: reminder, stateReminder: reminder)
                    .environmentObject(RemindersData())
                    .colorScheme(color)
                    .previewDisplayName("\(color) mode")
            }
        }
    }
}
