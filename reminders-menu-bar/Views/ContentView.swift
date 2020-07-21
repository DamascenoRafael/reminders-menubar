import SwiftUI
import EventKit

struct ContentView: View {
    @EnvironmentObject var remindersData: RemindersData

    @State var needRefreshIndicator: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            FormNewReminderView(reload: { self.reload() })
            List {
                ForEach(self.filteredReminderLists(needRefreshIndicator)) { reminderList in
                    VStack(alignment: .leading) {
                        Text(reminderList.title)
                            .font(.headline)
                            .foregroundColor(Color(reminderList.color))
                            .padding(.top, 5)
                        ForEach(self.filteredReminders(reminderList.reminders), id: \.calendarItemIdentifier) { reminder in
                            ReminderItemView(reminder: reminder, reload: { self.reload() })
                        }
                    }
                }
            }
            .onAppear {
                self.remindersData.loadCalendars()
                self.reload()
            }
            SettingsBarView()
        }
    }
    
    private func reload() {
        self.needRefreshIndicator.toggle()
    }
    
    private func filteredReminderLists(_: Bool) -> [ReminderList] {
        return RemindersService.instance.getReminders(of: self.remindersData.calendarIdentifiersFilter)
    }
    
    private func filteredReminders(_ reminders: [EKReminder]) -> [EKReminder] {
        if remindersData.showUncompletedOnly {
            return reminders
                .filter{ !$0.isCompleted }
                .sorted(by: { $0.creationDate!.compare($1.creationDate!) == .orderedDescending })
        } else {
            return
                reminders
                    .filter{ !$0.isCompleted }
                    .sorted(by: { $0.creationDate!.compare($1.creationDate!) == .orderedDescending })
                    +
                    reminders
                        .filter{ $0.isCompleted }
                        .sorted(by: { $0.completionDate!.compare($1.completionDate!) == .orderedDescending })
        }
    }
}


//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView().environmentObject(RemindersData())
//    }
//}
