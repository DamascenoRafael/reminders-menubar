import SwiftUI

struct UpcomingRemindersContent: View {
    @EnvironmentObject var remindersData: RemindersData
    @ObservedObject var userPreferences = UserPreferences.shared
    
    var body: some View {
        Group {
            if remindersData.upcomingReminders.isEmpty {
                NoReminderItemsView(emptyList: .noUpcomingReminders)
            }
            ForEach(remindersData.upcomingReminders) { reminderItem in
                ReminderItemView(
                    reminderItem: reminderItem,
                    isShowingCompleted: false,
                    showCalendarTitleOnDueDate: userPreferences.showUpcomingReminderListName
                )
            }
        }
    }
}

#Preview {
    UpcomingRemindersContent()
        .environmentObject(RemindersData())
        .environmentObject(CopyShortcutCoordinator())
}
