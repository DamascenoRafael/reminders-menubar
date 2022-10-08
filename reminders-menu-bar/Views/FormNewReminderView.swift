import SwiftUI
import EventKit

struct FormNewReminderView: View {
    @EnvironmentObject var remindersData: RemindersData
    @ObservedObject var userPreferences = UserPreferences.instance
    @State var date = Date()
    @State var showPopover = false
    @State var hasDueDate = false
    @State var hasDueTime = false
    
    @State var newReminderTitle = ""
    
    var body: some View {
        VStack {
            HStack {
                let placeholder = rmbLocalized(.newReminderTextFielPlaceholder)
                newReminderTextField(text: $newReminderTitle, placeholder: placeholder, date: $date, hasDueDate: $hasDueDate, hasDueTime: $hasDueTime)
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
                            SelectableView(title: calendar.title, isSelected: isSelected, color: Color(calendar.color), withDot: true)
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
    }
    
    @ViewBuilder
    func newReminderTextField(text: Binding<String>, placeholder: String, date: Binding<Date>, hasDueDate: Binding<Bool>, hasDueTime: Binding<Bool>) -> some View {
        VStack{
            if #available(macOS 15.0, *) {
                NewReminderTextFieldView(placeholder: placeholder, text: text)
                    .onSubmit {
                        createNewReminder()
                    }
            } else {
                TextField(placeholder, text: text, onCommit: {
                    createNewReminder()
                })
            }
            HStack{
                if hasDueDate.wrappedValue {
                    HStack(spacing: 0){
                        DatePicker(selection: date, displayedComponents: .date){
                            Image(systemName: "calendar")
                        }
                            .datePickerStyle(.field)
                        Button {
                            hasDueDate.wrappedValue = false
                        } label: {
                            Image(systemName: "xmark")
                        }
                    }
                    if hasDueTime.wrappedValue {
                        HStack(spacing: 0){
                            DatePicker(selection: date, displayedComponents: .hourAndMinute){
                                Image(systemName: "clock")
                            }
                                .datePickerStyle(.field)
                            Button {
                                hasDueTime.wrappedValue = false
                            } label: {
                                Image(systemName: "xmark")
                            }
                        }
                    }else{
                        Button {
                            hasDueTime.wrappedValue = true
                        } label: {
                            Label("Add Time", systemImage: "clock")
                        }
                    }
                }else{
                    Button {
                        hasDueDate.wrappedValue = true
                    } label: {
                        Label("Add Date", systemImage: "calendar")
                    }
                }
            }
        }
    }
    
    func createNewReminder() {
        guard !newReminderTitle.isEmpty else { return }
        
        RemindersService.instance.createNew(with: newReminderTitle, in: userPreferences.calendarForSaving)
        newReminderTitle = ""
    }
}

@available(macOS 12.0, *)
struct NewReminderTextFieldView: View {
    @FocusState private var newReminderTextFieldInFocus: Bool
    @ObservedObject var userPreferences = UserPreferences.instance
    
    var placeholder: String
    var text: Binding<String>
    
    var body: some View {
        let placeholdderText = Text(placeholder)
        TextField("", text: text, prompt: placeholdderText)
            .focused($newReminderTextFieldInFocus)
            .onReceive(userPreferences.$remindersMenuBarOpeningEvent) { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.newReminderTextFieldInFocus = true
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
