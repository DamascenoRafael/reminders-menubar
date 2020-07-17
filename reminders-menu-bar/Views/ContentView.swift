import SwiftUI
import EventKit

struct ContentView: View {
    @State private var newTask: String = ""
    @State private var remindersStore = RemindersService.instance.getReminders()
    
    var body: some View {
        VStack(spacing: 0) {
            Form {
                TextField("New task", text: $newTask)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(10)
            }
            .background(Color.darkTheme)
            List {
                ForEach(remindersStore) { reminderList in
                    VStack(alignment: .leading) {
                        Text(reminderList.title)
                            .font(.headline)
                            .foregroundColor(Color(reminderList.color))
                            .padding(.top, 5)
                        ForEach(reminderList.reminders, id: \.calendarItemIdentifier) { reminder in
                            ReminderItemView(reminder: reminder)
                        }
                    }
                }
            }
            .onAppear {
                self.remindersStore = RemindersService.instance.getReminders()
            }
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
