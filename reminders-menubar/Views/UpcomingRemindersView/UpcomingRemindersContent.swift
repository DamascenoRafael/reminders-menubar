import SwiftUI

struct UpcomingRemindersContent: View {
    @EnvironmentObject var remindersData: RemindersData
    
    var body: some View {
        Group{
            if remindersData.upcomingReminders.isEmpty {
                NoReminderItemsView(emptyList: .noUpcomingReminders)
            }
            ForEach(remindersData.upcomingReminders, id: \.calendarItemIdentifier) { reminder in
                ReminderItemView(reminder: reminder, showCalendarTitleOnDueDate: true)
            }
        }
    }
}

struct UpcomingRemindersContent_Previews: PreviewProvider {
    static var previews: some View {
        UpcomingRemindersContent().environmentObject(RemindersData())
    }
}
