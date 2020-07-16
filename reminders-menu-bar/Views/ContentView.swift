import SwiftUI

struct Reminder: Identifiable {
    var id = UUID()
    var title: String
}

struct ContentView: View {
    @State private var newTask: String = ""
    @State private var reminders = [
        Reminder(title: "Reminder 1"),
        Reminder(title: "Reminder 2"),
        Reminder(title: "Reminder 3"),
    ]
    
    var body: some View {
        VStack (spacing: 0) {
            Form {
                TextField("New task", text: $newTask)
                    .padding(.horizontal, 10)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding(.top)
            .background(Color.darkTheme)
            List {
                Text("Header")
                    .font(.headline)
                    .foregroundColor(.blue)
                    .padding(.top, 5)
                ForEach(reminders) { reminder in
                    ReminderItem(reminder: reminder.title)
                }
            }
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
