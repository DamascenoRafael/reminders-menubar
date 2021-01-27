import SwiftUI
import EventKit

struct ContentView: View {
    @EnvironmentObject var remindersData: RemindersData
    
    var body: some View {
        VStack(spacing: 0) {
            FormNewReminderView()
            List {
                ForEach(remindersData.filteredReminderLists) { reminderList in
                    VStack(alignment: .leading) {
                        CalendarTitleView(calendar: reminderList.calendar)
                        if let reminders = filteredReminders(reminderList.reminders), !reminders.isEmpty {
                            ForEach(reminders, id: \.calendarItemIdentifier) { reminder in
                                ReminderItemView(reminder: reminder)
                            }
                        } else {
                            NoReminderItemsView(calendarIsEmpty: reminderList.reminders.isEmpty)
                        }
                    }
                    .padding(.bottom, 5)
                }
            }
            .background(Color("backgroundTheme"))
            .onAppear {
                remindersData.update()
            }
            SettingsBarView()
        }
    }
    
    private func filteredReminders(_ reminders: [EKReminder]) -> [EKReminder] {
        let uncompletedReminders = reminders
            .filter { !$0.isCompleted }
            .sorted(by: {
                let firstDate = $0.creationDate ?? Date.distantPast
                let secondDate = $1.creationDate ?? Date.distantPast
                return firstDate.compare(secondDate) == .orderedDescending
            })
        
        if remindersData.showUncompletedOnly {
            return uncompletedReminders
        } else {
            let completedReminders = reminders
                .filter { $0.isCompleted }
                .sorted(by: {
                    let firstDate = $0.completionDate ?? Date.distantPast
                    let secondDate = $1.completionDate ?? Date.distantPast
                    return firstDate.compare(secondDate) == .orderedDescending
                })
            
            return uncompletedReminders + completedReminders
        }
    }
}

// struct ContentView_Previews: PreviewProvider {
//     static var previews: some View {
//         ContentView().environmentObject(RemindersData())
//     }
// }
