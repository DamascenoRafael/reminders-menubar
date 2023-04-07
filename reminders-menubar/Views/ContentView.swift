import SwiftUI
import EventKit

struct ContentView: View {
    @EnvironmentObject var remindersData: RemindersData
    @ObservedObject var userPreferences = UserPreferences.shared
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    
    var body: some View {
        VStack(spacing: 0) {
            FormNewReminderView()
            
            if userPreferences.atLeastOneFilterIsSelected {
                List {
                    if userPreferences.showUpcomingReminders {
                        Section(header: UpcomingRemindersTitle()) {
                            UpcomingRemindersContent()
                        }
                        .modifier(ListSectionSpacing())
                    }
                    ForEach(remindersData.filteredReminderLists) { reminderList in
                        Section(header: CalendarTitle(calendar: reminderList.calendar)) {
                            let reminders = filteredReminders(reminderList.reminders)
                            if reminders.isEmpty {
                                let calendarIsEmpty = reminderList.reminders.isEmpty
                                NoReminderItemsView(emptyList: calendarIsEmpty ? .noReminders : .allItemsCompleted)
                            }
                            ForEach(reminders, id: \.calendarItemIdentifier) { reminder in
                                ReminderItemView(reminder: reminder)
                            }
                        }
                        .modifier(ListSectionSpacing())
                    }
                }
                .listStyle(.plain)
            } else {
                VStack(spacing: 4) {
                    Text(rmbLocalized(.emptyListNoRemindersFilterTitle))
                        .multilineTextAlignment(.center)
                    Text(rmbLocalized(.emptyListNoRemindersFilterMessage))
                        .multilineTextAlignment(.center)
                }
                .frame(maxHeight: .infinity)
            }
            
            SettingsBarView()
        }
        .background(Color.rmbColor(for: .backgroundTheme, and: colorSchemeContrast).padding(-80))
    }
    
    private func filteredReminders(_ reminders: [EKReminder]) -> [EKReminder] {
        let uncompletedReminders = reminders.filter { !$0.isCompleted }.sortedRemindersByPriority
        
        if userPreferences.showUncompletedOnly {
            return uncompletedReminders
        }
        
        let completedReminders = reminders.filter { $0.isCompleted }.sortedRemindersByPriority
        return uncompletedReminders + completedReminders
    }
}

struct ListSectionSpacing: ViewModifier {
    func body(content: Content) -> some View {
        return content
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 8, trailing: 0))
            .padding(.horizontal, 8)
    }
}

 struct ContentView_Previews: PreviewProvider {
     static var previews: some View {
         ContentView().environmentObject(RemindersData())
     }
 }
