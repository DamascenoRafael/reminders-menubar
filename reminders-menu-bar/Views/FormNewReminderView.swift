import SwiftUI
import EventKit

struct FormNewReminderView: View {
    @EnvironmentObject var remindersData: RemindersData
    @ObservedObject var userPreferences = UserPreferences.shared
    
    @State var rmbReminder = RmbReminder()
    @State var isShowingDueDateOptions = false
    
    var body: some View {
        Form {
            HStack(alignment: .top) {
                let placeholder = rmbLocalized(.newReminderTextFielPlaceholder)
                newReminderTextFieldView(placeholder: placeholder)
                .padding(.vertical, 8)
                .padding(.horizontal, 8)
                .padding(.leading, 22)
                .background(
                    userPreferences.backgroundIsTransparent ?
                        Color("textFieldBackgroundTransparent") :
                        Color("textFieldBackground")
                )
                .cornerRadius(8)
                .textFieldStyle(PlainTextFieldStyle())
                .overlay(
                    Image(systemName: "plus.circle.fill")
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .foregroundColor(.gray)
                        .padding([.top, .leading], 8)
                )
                
                Menu {
                    ForEach(remindersData.calendars, id: \.calendarIdentifier) { calendar in
                        Button(action: { userPreferences.calendarForSaving = calendar }) {
                            let isSelected =
                                userPreferences.calendarForSaving?.calendarIdentifier == calendar.calendarIdentifier
                            SelectableView(title: calendar.title, isSelected: isSelected, color: Color(calendar.color))
                        }
                    }
                } label: {
                }
                .menuStyle(BorderlessButtonMenuStyle())
                .frame(width: 14, height: 16)
                .padding(8)
                .padding(.trailing, 2)
                .background(Color(userPreferences.calendarForSaving?.color ?? .white))
                .cornerRadius(8)
                .help(rmbLocalized(.newReminderCalendarSelectionToSaveHelp))
            }
        }
        .padding(10)
        .onChange(of: rmbReminder.title) { newValue in
            withAnimation(.easeOut(duration: 0.3)) {
                isShowingDueDateOptions = !newValue.isEmpty
                rmbReminder.updateWithDateParser()
            }
            if newValue.isEmpty {
                rmbReminder = RmbReminder()
            }
        }
    }
    
    @ViewBuilder
    func newReminderTextFieldView(placeholder: String) -> some View {
        VStack(alignment: .leading) {
            if #available(macOS 12.0, *) {
                ReminderTextField(placeholder: placeholder, text: $rmbReminder.title, onSubmit: createNewReminder)
            } else {
                LegacyReminderTextField(placeholder: placeholder, text: $rmbReminder.title, onSubmit: createNewReminder)
            }
            if isShowingDueDateOptions {
                reminderDueDateOptionsView(date: $rmbReminder.date,
                                           hasDueDate: $rmbReminder.hasDueDate,
                                           hasTime: $rmbReminder.hasTime)
            }
        }
    }
    
    func createNewReminder() {
        guard !rmbReminder.title.isEmpty,
              let calendarForSaving = userPreferences.calendarForSaving else {
            return
        }
        
        RemindersService.shared.createNew(with: rmbReminder, in: calendarForSaving)
        rmbReminder = RmbReminder()
    }
}

@available(macOS 12.0, *)
struct ReminderTextField: View {
    @FocusState private var newReminderTextFieldInFocus: Bool
    @ObservedObject var userPreferences = UserPreferences.shared
    
    var placeholder: String
    var text: Binding<String>
    var onSubmit: () -> Void
    
    var body: some View {
        let placeholdderText = Text(placeholder)
        TextField("", text: text, prompt: placeholdderText)
            .onSubmit {
                onSubmit()
            }
            .focused($newReminderTextFieldInFocus)
            .onReceive(userPreferences.$remindersMenuBarOpeningEvent) { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.newReminderTextFieldInFocus = true
                }
            }
    }
}

struct LegacyReminderTextField: NSViewRepresentable {
    let placeholder: String
    var text: Binding<String>
    var onSubmit: () -> Void
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField()
        textField.delegate = context.coordinator
        textField.placeholderString = placeholder
        textField.isBordered = false
        textField.font = .systemFont(ofSize: NSFont.systemFontSize)
        
        textField.backgroundColor = NSColor.clear
        
        return textField
    }
    
    func updateNSView(_ nsView: NSTextField, context: Context) {
        nsView.stringValue = self.text.wrappedValue
    }
    
    class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: LegacyReminderTextField
        
        init(_ parent: LegacyReminderTextField) {
            self.parent = parent
        }
        
        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                guard !textView.string.isEmpty else {
                    return false
                }
                self.parent.onSubmit()
                return true
            }
            return false
        }
        
        func controlTextDidChange(_ obj: Notification) {
            if let textField = obj.object as? NSTextField {
                self.parent.text.wrappedValue = textField.stringValue
            }
        }
    }
}

@ViewBuilder
func reminderDueDateOptionsView(date: Binding<Date>, hasDueDate: Binding<Bool>, hasTime: Binding<Bool>) -> some View {
    HStack {
        reminderRemindDateTimeOptionView(date: date, components: .date, hasComponent: hasDueDate)
            .modifier(RemindDateTimeCapsuleStyle())
        if hasDueDate.wrappedValue {
            reminderRemindDateTimeOptionView(date: date, components: .time, hasComponent: hasTime)
                .modifier(RemindDateTimeCapsuleStyle())
        }
    }
}

@ViewBuilder
func reminderRemindDateTimeOptionView(date: Binding<Date>,
                                      components: RmbDatePicker.DatePickerComponents,
                                      hasComponent: Binding<Bool>) -> some View {
    let pickerIcon = components == .time ? "clock" : "calendar"
    
    let addTimeButtonText = rmbLocalized(.newReminderAddTimeButton)
    let addDateButtonText = rmbLocalized(.newReminderAddDateButton)
    let pickerAddComponentText = components == .time ? addTimeButtonText : addDateButtonText
    
    if hasComponent.wrappedValue {
        HStack {
            Image(systemName: pickerIcon)
                .font(.system(size: 12))
            RmbDatePicker(selection: date, components: components)
                .font(.systemFont(ofSize: 12, weight: .light))
                .fixedSize(horizontal: true, vertical: true)
                .padding(.top, 2)
            Button {
                hasComponent.wrappedValue = false
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12))
            }
            .buttonStyle(.borderless)
            .frame(width: 5, height: 5, alignment: .center)
        }
    } else {
        Button {
            hasComponent.wrappedValue = true
        } label: {
            Label(pickerAddComponentText, systemImage: pickerIcon)
                .font(.system(size: 12))
        }
        .buttonStyle(.borderless)
    }
}

struct RemindDateTimeCapsuleStyle: ViewModifier {
    func body(content: Content) -> some View {
        return content
            .frame(height: 20)
            .padding(.horizontal, 8)
            .background(Color.secondary.opacity(0.2))
            .clipShape(Capsule())
    }
}

struct FormNewReminderView_Previews: PreviewProvider {
    static var reminder: EKReminder {
        let calendar = EKCalendar(for: .reminder, eventStore: .init())
        calendar.color = .systemTeal
        
        let reminder = EKReminder(eventStore: .init())
        reminder.title = "Look for awesome projects on GitHub"
        reminder.isCompleted = false
        reminder.calendar = calendar
        
        let dateComponents = Date().dateComponents(withTime: true)
        reminder.dueDateComponents = dateComponents
        
        return reminder
    }
    
    static var previews: some View {
        Group {
            ForEach(ColorScheme.allCases, id: \.self) { color in
                FormNewReminderView(rmbReminder: RmbReminder(reminder: reminder), isShowingDueDateOptions: true)
                    .environmentObject(RemindersData())
                    .colorScheme(color)
                    .previewDisplayName("\(color) mode")
            }
        }
    }
}
