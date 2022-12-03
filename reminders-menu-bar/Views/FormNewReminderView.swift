import SwiftUI
import EventKit

struct FormNewReminderView: View {
    @EnvironmentObject var remindersData: RemindersData
    @ObservedObject var userPreferences = UserPreferences.instance
    
    @State var rmbReminder = RmbReminder()
    
    var body: some View {
        Form {
            HStack {
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
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundColor(.gray)
                        .padding(.leading, 8)
                )
                
                Menu {
                    ForEach(remindersData.calendars, id: \.calendarIdentifier) { calendar in
                        Button(action: { userPreferences.calendarForSaving = calendar }) {
                            let isSelected =
                                userPreferences.calendarForSaving.calendarIdentifier == calendar.calendarIdentifier
                            SelectableView(title: calendar.title, isSelected: isSelected, color: Color(calendar.color))
                        }
                    }
                } label: {
                }
                .menuStyle(BorderlessButtonMenuStyle())
                .frame(width: 14, height: 16)
                .padding(8)
                .padding(.trailing, 2)
                .background(Color(userPreferences.calendarForSaving.color))
                .cornerRadius(8)
                .help(rmbLocalized(.newReminderCalendarSelectionToSaveHelp))
            }
        }
        .padding(10)
        .animation(.default)
    }
    
    @ViewBuilder
    func newReminderTextFieldView(placeholder: String) -> some View {
        VStack(alignment: .leading) {
            if #available(macOS 12.0, *) {
                ReminderTextField(placeholder: placeholder, text: $rmbReminder.title, onSubmit: createNewReminder)
            } else {
                LegacyReminderTextField(placeholder: placeholder, text: $rmbReminder.title, onSubmit: createNewReminder)
            }
            if !rmbReminder.title.isEmpty {
                reminderDueDateOptionsView(date: $rmbReminder.date, hasDueDate: $rmbReminder.hasDueDate, hasTime: $rmbReminder.hasTime)
            }
        }
    }
    
    @ViewBuilder
    func reminderDueDateOptionsView(date: Binding<Date>, hasDueDate: Binding<Bool>, hasTime: Binding<Bool>) -> some View {
        HStack {
            reminderRemindDateOptionView(date: date, hasDueDate: hasDueDate)
            if hasDueDate.wrappedValue {
                reminderRemindTimeOptionView(date: date, hasTime: hasTime)
            }
        }
        .animation(.none)
    }
    
    @ViewBuilder
    func reminderRemindDateOptionView(date: Binding<Date>, hasDueDate: Binding<Bool>) -> some View {
        if hasDueDate.wrappedValue {
            HStack(spacing: 0) {
                DatePicker(selection: date, displayedComponents: .date) {
                    Image(systemName: "calendar")
                }
                    .datePickerStyle(.field)
                Button {
                    hasDueDate.wrappedValue = false
                } label: {
                    Image(systemName: "xmark")
                }
            }
        } else {
            Button {
                hasDueDate.wrappedValue = true
            } label: {
                Label("Add Date", systemImage: "calendar")
            }
        }
    }
    
    @ViewBuilder
    func reminderRemindTimeOptionView(date: Binding<Date>, hasTime: Binding<Bool>) -> some View {
        if hasTime.wrappedValue {
            HStack(spacing: 0) {
                DatePicker(selection: date, displayedComponents: .hourAndMinute) {
                    Image(systemName: "clock")
                }
                    .datePickerStyle(.field)
                Button {
                    hasTime.wrappedValue = false
                } label: {
                    Image(systemName: "xmark")
                }
            }
        } else {
            Button {
                hasTime.wrappedValue = true
            } label: {
                Label("Add Time", systemImage: "clock")
            }
        }
    }
    
    func createNewReminder() {
        guard !rmbReminder.title.isEmpty else { return }
        
        RemindersService.instance.createNew(with: rmbReminder, in: userPreferences.calendarForSaving)
        rmbReminder = RmbReminder()
    }
}

@available(macOS 12.0, *)
struct ReminderTextField: View {
    @FocusState private var newReminderTextFieldInFocus: Bool
    @ObservedObject var userPreferences = UserPreferences.instance
    
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

struct FormNewReminderView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ForEach(ColorScheme.allCases, id: \.self) { color in
                FormNewReminderView()
                    .environmentObject(RemindersData())
                    .colorScheme(color)
                    .previewDisplayName("\(color) mode")
            }
        }
    }
}
