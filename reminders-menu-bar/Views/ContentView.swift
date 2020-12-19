import SwiftUI
import EventKit

struct ContentView: View {
    @EnvironmentObject var remindersData: RemindersData

    @State var needRefreshIndicator = false
    
    var body: some View {
        VStack(spacing: 0) {
            FormNewReminderView(reload: { reload() })
            List {
                ForEach(filteredReminderLists(needRefreshIndicator)) { reminderList in
                    VStack(alignment: .leading) {
                        Text(reminderList.title)
                            .font(.headline)
                            .foregroundColor(Color(reminderList.color))
                            .padding(.bottom, 5)
                        ForEach(filteredReminders(reminderList.reminders), id: \.calendarItemIdentifier) { reminder in
                            ReminderItemView(reminder: reminder, reload: { reload() })
                        }
                    }
                    .padding(.bottom, 5)
                }
            }
            .onAppear {
                remindersData.loadCalendars()
                reload()
            }
            SettingsBarView()
        }
    }
    
    private func reload() {
        needRefreshIndicator.toggle()
    }
    
    private func filteredReminderLists(_: Bool) -> [ReminderList] {
        return RemindersService.instance.getReminders(of: remindersData.calendarIdentifiersFilter)
    }
    
    private func filteredReminders(_ reminders: [EKReminder]) -> [EKReminder] {
        let uncompletedReminders = reminders
            .filter{ !$0.isCompleted }
            .sorted(by: { $0.creationDate!.compare($1.creationDate!) == .orderedDescending })
        
        if remindersData.showUncompletedOnly {
            return uncompletedReminders
        } else {
            let completedReminders = reminders
                .filter{ $0.isCompleted }
                .sorted(by: { $0.completionDate!.compare($1.completionDate!) == .orderedDescending })
            
            return uncompletedReminders + completedReminders
        }
    }
}


//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView().environmentObject(RemindersData())
//    }
//}
