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
                            let uncompletedIsEmpty = reminderList.uncompletedReminders.isEmpty
                            let completedIsEmpty = reminderList.completedReminders.isEmpty
                            let calendarIsEmpty = uncompletedIsEmpty && completedIsEmpty
                            let isShowingCompleted = !userPreferences.showUncompletedOnly
                            let viewIsEmpty = isShowingCompleted ? calendarIsEmpty : uncompletedIsEmpty
                            if viewIsEmpty {
                                NoReminderItemsView(emptyList: calendarIsEmpty ? .noReminders : .allItemsCompleted)
                            }
                            ForEach(reminderList.uncompletedReminders, id: \.calendarItemIdentifier) { reminder in
                                ReminderItemView(reminder: reminder)
                            }
                            if isShowingCompleted {
                                ForEach(reminderList.completedReminders, id: \.calendarItemIdentifier) { reminder in
                                    ReminderItemView(reminder: reminder)
                                }
                            }
                        }
                        .modifier(ListSectionSpacing())
                    }
                }
                .listStyle(.plain)
                .animation(.default, value: remindersData.filteredReminderLists)
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
