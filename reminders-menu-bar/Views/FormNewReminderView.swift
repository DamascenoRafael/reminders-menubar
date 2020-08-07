import SwiftUI
import EventKit

struct FormNewReminderView: View {
    @EnvironmentObject var remindersData: RemindersData
    
    @State var newReminderTitle = ""
    @State var selectedCalendar = RemindersService.instance.getDefaultCalendar()
    var reload: () -> Void
    
    var body: some View {
        Form {
            HStack {
                TextField("Type a reminder and hit enter", text: $newReminderTitle, onCommit: {
                    guard !self.newReminderTitle.isEmpty else { return }
                    
                    RemindersService.instance.createNew(with: self.newReminderTitle, in: self.selectedCalendar)
                    self.newReminderTitle = ""
                    self.reload()
                })
                    .padding(5)
                    .padding(.horizontal, 10)
                    .padding(.leading, 15)
                    .background(Color("textFieldBackground"))
                    .cornerRadius(8)
                    .textFieldStyle(PlainTextFieldStyle())
                    .overlay(
                        Image("plus.circle.filled")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundColor(.gray)
                            .padding(.leading, 5)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color("textFieldStrock"), lineWidth: 0.8)
                    )
                MenuButton(label:
                    Image("circle.filled")
                        .resizable()
                        .frame(width: 6, height: 6)
                        .foregroundColor(Color(selectedCalendar.color))
                ) {
                    ForEach(remindersData.calendars, id: \.calendarIdentifier) { calendar in
                        Button(action: { self.selectedCalendar = calendar }) {
                            HStack {
                                Image("circle.filled")
                                    .resizable()
                                    .frame(width: 6, height: 6)
                                    .foregroundColor(Color(calendar.color))
                                Text(calendar.title)
                            }
                        }
                    }
                }
                .menuButtonStyle(BorderlessPullDownMenuButtonStyle())
                .frame(width: 25)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(Color("textFieldBackground"))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color("textFieldStrock"), lineWidth: 0.8)
                )
            }
            .padding(10)
        }
        .background(Color("backgroundTheme"))
    }
}

struct FormNewReminderView_Previews: PreviewProvider {
    static var calendar: EKCalendar {
        let calendar = EKCalendar(for: .reminder, eventStore: .init())
        calendar.color = .systemTeal
        return calendar
    }
    
    static func reload() { return }

    static var previews: some View {
        Group {
            ForEach(ColorScheme.allCases, id: \.self) { color in
                FormNewReminderView(selectedCalendar: calendar, reload: reload)
                    .environmentObject(RemindersData())
                    .colorScheme(color)
                    .previewDisplayName("\(color) mode")
            }
        }
    }
}
