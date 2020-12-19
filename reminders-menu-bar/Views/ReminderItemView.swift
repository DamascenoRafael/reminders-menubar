import SwiftUI
import EventKit

struct ReminderItemView: View {
    @EnvironmentObject var remindersData: RemindersData
    
    @State private var showingRemoveAlert = false
    
    @State var reminder: EKReminder
    var reload: () -> Void
    
    var body: some View {
        HStack(alignment: .top) {
            Button(action: {
                reminder.isCompleted.toggle()
                RemindersService.instance.save(reminder: reminder)
                reload()
            }) {
                Image(systemName: reminder.isCompleted ? "largecircle.fill.circle" : "circle")
                    .resizable()
                    .frame(width: 18, height: 18)
                    .padding(.top, 1)
                    .foregroundColor(Color(reminder.calendar.color))
            }.buttonStyle(PlainButtonStyle())
            VStack(spacing: 8) {
                HStack {
                    Text(reminder.title)
                    Spacer()
                    MenuButton(label:
                        Image(systemName: "ellipsis")
                    ) {
                        MenuButton(label:
                            HStack {
                                Image(systemName: "folder")
                                Text("Move to ...")
                            }
                        ) {
                            ForEach(remindersData.calendars.filter({ $0.calendarIdentifier != reminder.calendar.calendarIdentifier }), id: \.calendarIdentifier) { calendar in
                                Button(action: {
                                    reminder.calendar = calendar
                                    RemindersService.instance.save(reminder: reminder)
                                    reload()
                                }) {
                                    Text(calendar.title)
                                        .foregroundColor(Color(calendar.color))
                                }
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
                                Text("Remove")
                            }
                        }
                    }
                    .menuButtonStyle(BorderlessButtonMenuButtonStyle())
                    .frame(width: 16, height: 16)
                    .padding(.top, 1)
                    .padding(.trailing, 10)
                }
                .alert(isPresented: $showingRemoveAlert) {
                    Alert(title: Text("Remove reminder?"),
                          message: Text("This action will remove '\(reminder.title)' and cannot be undone"),
                          primaryButton: .destructive(Text("Remove"), action: {
                            RemindersService.instance.remove(reminder: reminder)
                            reload()
                          }),
                          secondaryButton: .cancel(Text("Cancelar"))
                    )
                }
                Divider()
            }
        }
        .background(Color("backgroundTheme"))
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
    
    static func reload() { return }
    
    static var previews: some View {
        Group {
            ForEach(ColorScheme.allCases, id: \.self) { color in
                ReminderItemView(reminder: reminder, reload: reload)
                    .environmentObject(RemindersData())
                    .colorScheme(color)
                    .previewDisplayName("\(color) mode")
            }
        }
    }
}
