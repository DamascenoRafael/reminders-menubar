import SwiftUI
import EventKit

struct ContentView: View {
    @EnvironmentObject var remindersData: RemindersData
    @ObservedObject var userPreferences = UserPreferences.instance
    
    var body: some View {
        VStack(spacing: 0) {
            FormNewReminderView()
            List {
                if userPreferences.showUpcomingReminders {
                    UpcomingRemindersList()
                }
                ForEach(remindersData.filteredReminderLists) { reminderList in
                    VStack(alignment: .leading) {
                        CalendarTitleView(calendar: reminderList.calendar)
                        let reminders = filteredReminders(reminderList.reminders)
                        if reminders.isEmpty {
                            let calendarIsEmpty = reminderList.reminders.isEmpty
                            NoReminderItemsView(emptyList: calendarIsEmpty ? .noReminders : .allItemsCompleted)
                        }
                        ForEach(reminders, id: \.calendarItemIdentifier) { reminder in
                            ReminderItemView(reminder: reminder)
                        }
                    }
                    .padding(.bottom, 5)
                }
            }
            .onAppear {
                remindersData.update()
            }
            SettingsBarView()
        }
        .background(Color("backgroundTheme").opacity(userPreferences.backgroundIsTransparent ? 0.3 : 1.0))
    }
    
    private func filteredReminders(_ reminders: [EKReminder]) -> [EKReminder] {
        let uncompletedReminders = reminders.filter { !$0.isCompleted }.sortedReminders
        
        if userPreferences.showUncompletedOnly {
            return uncompletedReminders
        }
        
        let completedReminders = reminders.filter { $0.isCompleted }.sortedReminders
        return uncompletedReminders + completedReminders
    }
}

// struct ContentView_Previews: PreviewProvider {
//     static var previews: some View {
//         ContentView().environmentObject(RemindersData())
//     }
// }
