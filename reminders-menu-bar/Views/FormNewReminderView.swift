import SwiftUI
import EventKit

struct FormNewReminderView: View {
    @EnvironmentObject var remindersData: RemindersData
    @ObservedObject var userPreferences = UserPreferences.instance
    
    @State var newReminderTitle = ""
    
    var body: some View {
        Form {
            HStack {
                let placeholder = rmbLocalized(.newReminderTextFielPlaceholder)
                newReminderTextField(text: $newReminderTitle, placeholder: placeholder)
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
    }
    
    @ViewBuilder
    func newReminderTextField(text: Binding<String>, placeholder: String) -> some View {
        if #available(macOS 12.0, *) {
            let placeholdderText = Text(placeholder)
            TextField("", text: text, prompt: placeholdderText)
            .onSubmit {
                createNewReminder()
            }
        } else {
            TextField(placeholder, text: text, onCommit: {
                createNewReminder()
            })
        }
    }
    
    func createNewReminder() {
        guard !newReminderTitle.isEmpty else { return }
        
        RemindersService.instance.createNew(with: newReminderTitle, in: userPreferences.calendarForSaving)
        newReminderTitle = ""
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
