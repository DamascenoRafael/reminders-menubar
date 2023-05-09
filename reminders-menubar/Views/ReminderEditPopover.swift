import SwiftUI
import EventKit

struct ReminderEditPopover: View {
    @Binding var isPresented: Bool
    @Binding var focusOnTitle: Bool
    
    @State var rmbReminder: RmbReminder
    var ekReminder: EKReminder
    
    init(isPresented: Binding<Bool>, focusOnTitle: Binding<Bool>, reminder: EKReminder) {
        _isPresented = isPresented
        _focusOnTitle = focusOnTitle
        self.ekReminder = reminder
        _rmbReminder = State(initialValue: RmbReminder(reminder: reminder))
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            TextField(rmbLocalized(.editReminderTitleTextFieldPlaceholder), text: $rmbReminder.title)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.title3)
                .modifier(FocusOnAppear(isEnabled: focusOnTitle))
            
            TextField(rmbLocalized(.editReminderNotesTextFieldPlaceholder), text: $rmbReminder.notes ?? "")
                .textFieldStyle(PlainTextFieldStyle())
            
            Divider()
            
            ReminderSection(rmbLocalized(.editReminderRemindMeSection)) {
                Toggle(rmbLocalized(.editReminderRemindDateOption), isOn: $rmbReminder.hasDueDate)
                
                if rmbReminder.hasDueDate {
                    RmbDatePicker(selection: $rmbReminder.date, components: .date)
                        .fixedSize(horizontal: true, vertical: false)
                        .padding(.leading, 16)
                    
                    Toggle(rmbLocalized(.editReminderRemindTimeOption), isOn: $rmbReminder.hasTime)
                    
                    if rmbReminder.hasTime {
                        RmbDatePicker(selection: $rmbReminder.date, components: .time)
                            .fixedSize(horizontal: true, vertical: false)
                            .padding(.leading, 16)
                    }
                }
            }
            
            Divider()
            
            ReminderSection(rmbLocalized(.editReminderPrioritySection)) {
                Picker("", selection: $rmbReminder.priority) {
                    Text(rmbLocalized(.editReminderPriorityLowOption)).tag(EKReminderPriority.low)
                    Text(rmbLocalized(.editReminderPriorityMediumOption)).tag(EKReminderPriority.medium)
                    Text(rmbLocalized(.editReminderPriorityHighOption)).tag(EKReminderPriority.high)
                    Divider()
                    Text(rmbLocalized(.editReminderPriorityNoneOption)).tag(EKReminderPriority.none)
                }
                .labelsHidden()
                .fixedSize(horizontal: true, vertical: false)
            }
        }
        .frame(width: 300, alignment: .center)
        .padding()
        .modifier(OnKeyboardShortcut(shortcut: .defaultAction, action: {
            isPresented = false
        }))
        .onAppear {
            removeFocusFromFirstResponder()
        }
        .onDisappear {
            focusOnTitle = false
            ekReminder.update(with: rmbReminder)
            if ekReminder.hasChanges {
                RemindersService.shared.save(reminder: ekReminder)
            }
        }
    }
}

struct ReminderSection<Content>: View where Content: View {
    let sectionName: String
    let sectionView: Content
    
    init(_ sectionName: String, @ViewBuilder sectionView: () -> Content) {
      self.sectionName = sectionName
      self.sectionView = sectionView()
    }
    
    var body: some View {
        HStack(alignment: .top) {
            Text(sectionName)
                .frame(width: 100, alignment: .trailing)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading) {
                sectionView
            }
        }
    }
}

struct ReminderEditPopover_Previews: PreviewProvider {
    static var reminder: EKReminder {
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
    
    static var previews: some View {
        ReminderEditPopover(isPresented: .constant(true), focusOnTitle: .constant(false), reminder: reminder)
    }
}
