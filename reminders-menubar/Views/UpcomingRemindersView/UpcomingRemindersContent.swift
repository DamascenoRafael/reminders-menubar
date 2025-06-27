import SwiftUI

struct UpcomingRemindersContent: View {
    @EnvironmentObject var remindersData: RemindersData
    
    var body: some View {
        Group {
            if remindersData.upcomingReminders.isEmpty {
                NoReminderItemsView(emptyList: .noUpcomingReminders)
            }
            ForEach(remindersData.upcomingReminders) { reminderItem in
                ReminderItemView(
                    reminderItem: reminderItem,
                    isShowingCompleted: false,
                    showCalendarTitleOnDueDate: true
                )
            }
        }
    }
}

struct UpcomingRemindersContent_Previews: PreviewProvider {
    static var previews: some View {
        UpcomingRemindersContent().environmentObject(RemindersData())
    }
}
