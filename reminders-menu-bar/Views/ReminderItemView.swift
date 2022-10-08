import SwiftUI
import EventKit

struct ReminderItemView: View {
    @EnvironmentObject var remindersData: RemindersData
    
    var reminder: EKReminder
    var showCalendarTitleOnDueDate = false
    @State var reminderItemIsHovered = false
    
    @State private var showingRenameSheet = false
    @State private var possibleNewTitle = ""
    
    @State private var showingRemoveAlert = false
    @State private var hasBeenRemoved = false
    
    var body: some View {
        HStack(alignment: .top) {
            Button(action: {
                reminder.isCompleted.toggle()
                RemindersService.instance.save(reminder: reminder)
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
                    Text(reminder.title)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                    MenuButton(label:
                        Image(systemName: "ellipsis")
                    ) {
                        let otherCalendars = remindersData.calendars.filter {
                            $0.calendarIdentifier != reminder.calendar.calendarIdentifier
                        }
                        if !otherCalendars.isEmpty {
                            MoveToOptionMenu(reminder: reminder, availableCalendars: otherCalendars)
                        }
                        
                        Button(action: {
                            possibleNewTitle = reminder.title
                            showingRenameSheet = true
                        }) {
                            HStack {
                                Image(systemName: "pencil")
                                Text(rmbLocalized(.renameReminderOptionButton))
                            }
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
                    .opacity(reminderItemIsHovered ? 1 : 0)
                }
                .alert(isPresented: $showingRemoveAlert) {
                    removeReminderAlert()
                }
                .onChange(of: showingRemoveAlert) { isShowing in
                    AppDelegate.instance.changeBehaviorBasedOnModal(isShowing: isShowing)
                }
                .sheet(isPresented: $showingRenameSheet) {
                    renameReminderSheet()
                }
                .onChange(of: showingRenameSheet) { isShowing in
                    AppDelegate.instance.changeBehaviorBasedOnModal(isShowing: isShowing)
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
                
                Divider()
            }
        }
        .onHover { isHovered in
            reminderItemIsHovered = isHovered
        }
        .onDisappear(perform: {
            AppDelegate.instance.changeBehaviorToDismissIfNeeded()
            if hasBeenRemoved {
                RemindersService.instance.commitChanges()
            }
        })
    }
    
    func renameReminder(newTitle: String) {
        reminder.title = newTitle
        RemindersService.instance.save(reminder: reminder)
    }
    
    func removeReminderAlert() -> Alert {
        Alert(title: Text(rmbLocalized(.removeReminderAlertTitle)),
              message: Text(rmbLocalized(.removeReminderAlertMessage, arguments: reminder.title)),
              primaryButton: .destructive(Text(rmbLocalized(.removeReminderAlertConfirmButton)), action: {
                RemindersService.instance.remove(reminder: reminder)
                hasBeenRemoved = true
              }),
              secondaryButton: .cancel(Text(rmbLocalized(.removeReminderAlertCancelButton)))
        )
    }
    
    @ViewBuilder
    func renameReminderSheet() -> some View {
        VStack {
            Text(rmbLocalized(.renameReminderAlertTitle))
                .font(.headline)
                .padding()
            
            Text(rmbLocalized(.renameReminderAlertMessage))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal)
                .padding(.bottom)
            
            TextEditor(text: Binding(
                get: {
                    possibleNewTitle
                },
                set: { value in
                    var newValue = value
                    let userInsertLineBreak = value.contains("\n")
                    // NOTE: User may have copied a line break along with the new title, so we check if
                    // the value of 'possibleNewTitle' has increased by only one character (only the line break).
                    let userHitEnter = userInsertLineBreak && newValue.count == possibleNewTitle.count + 1
                    if userInsertLineBreak {
                        newValue = newValue.replacingOccurrences(of: "\n", with: "")
                    }
                    possibleNewTitle = newValue
                    if userHitEnter {
                        showingRenameSheet = false
                        renameReminder(newTitle: possibleNewTitle)
                    }
                }
            ))
                .padding(8)
                .background(Color("textFieldBackground"))
                .cornerRadius(8)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(5)
                .padding(.horizontal)
            
            HStack {
                Button {
                    showingRenameSheet = false
                } label: {
                    Text(rmbLocalized(.renameReminderAlertCancelButton))
                        .frame(maxWidth: .infinity)
                }
                .keyboardShortcut(.cancelAction)

                Button {
                    showingRenameSheet = false
                    renameReminder(newTitle: possibleNewTitle)
                } label: {
                    Text(rmbLocalized(.renameReminderAlertConfirmButton))
                        .frame(maxWidth: .infinity)
                }
            }
            .padding()
        }
        .frame(width: 250, alignment: .center)
        .padding()
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
                    RemindersService.instance.save(reminder: reminder)
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
                ReminderItemView(reminder: reminder)
                    .environmentObject(RemindersData())
                    .colorScheme(color)
                    .previewDisplayName("\(color) mode")
            }
        }
    }
}
