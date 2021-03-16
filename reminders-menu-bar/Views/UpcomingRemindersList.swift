import SwiftUI

struct UpcomingRemindersList: View {
    @EnvironmentObject var remindersData: RemindersData
    
    var body: some View {
        VStack(alignment: .leading) {
            UpcomingRemindersTitle()
            if remindersData.upcomingReminders.isEmpty {
                NoReminderItemsView(emptyList: .noUpcomingReminders)
            }
            ForEach(remindersData.upcomingReminders, id: \.calendarItemIdentifier) { reminder in
                ReminderItemView(reminder: reminder, showCalendarTitleOnDueDate: true)
            }
        }
    }
}

struct UpcomingRemindersList_Previews: PreviewProvider {
    static var previews: some View {
        UpcomingRemindersList().environmentObject(RemindersData())
    }
}
