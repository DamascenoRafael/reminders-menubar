import SwiftUI
import EventKit

struct ContentView: View {
    @State private var calendars: [EKCalendar] = []
    @State private var filteredCalendarIdentifiers: [String] = []
    @State private var isFilterEnabled = true
    @State var needRefreshIndicator: Bool = false

    
    var body: some View {
        VStack(spacing: 0) {
            FormNewReminderView(reload: { self.reload() }, calendars: $calendars)
            List {
                ForEach(self.filteredReminderLists(by: self.filteredCalendarIdentifiers, needRefreshIndicator)) { reminderList in
                    VStack(alignment: .leading) {
                        Text(reminderList.title)
                            .font(.headline)
                            .foregroundColor(Color(reminderList.color))
                            .padding(.top, 5)
                        ForEach(self.filteredReminders(reminderList.reminders), id: \.calendarItemIdentifier) { reminder in
                            ReminderItemView(reminder: reminder, reload: { self.reload() }, calendars: self.$calendars)
                        }
                    }
                }
            }
            .onAppear {
                self.reload()
            }
            SettingsBarView(isFilterEnabled: $isFilterEnabled, calendars: $calendars, filteredCalendarIdentifiers: $filteredCalendarIdentifiers)
        }
    }
    
    private func reload() {
        let calendars = RemindersService.instance.getCalendars()
        if (self.calendars.isEmpty) {
            self.filteredCalendarIdentifiers = calendars.map({ $0.calendarIdentifier })
        }
        self.calendars = calendars
        self.needRefreshIndicator.toggle()
    }
    
    private func filteredReminderLists(by filter: [String], _: Bool) -> [ReminderList] {
        return RemindersService.instance.getReminders(of: filter)
    }
    
    private func filteredReminders(_ reminders: [EKReminder]) -> [EKReminder] {
        if isFilterEnabled {
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


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
