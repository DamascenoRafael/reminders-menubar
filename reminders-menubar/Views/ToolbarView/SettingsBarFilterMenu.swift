import SwiftUI

struct SettingsBarFilterMenu: View {
    @EnvironmentObject var remindersData: RemindersData
    @ObservedObject var userPreferences = UserPreferences.shared
    
    var body: some View {
        Menu {
            VStack {
                Button(action: {
                    userPreferences.showUpcomingReminders.toggle()
                }) {
                    let isSelected = userPreferences.showUpcomingReminders
                    SelectableView(title: rmbLocalized(.upcomingRemindersTitle), isSelected: isSelected)
                }
                
                Divider()
                
                ForEach(remindersData.calendars, id: \.calendarIdentifier) { calendar in
                    let calendarIdentifier = calendar.calendarIdentifier
                    Button(action: {
                        let index = remindersData.calendarIdentifiersFilter.firstIndex(of: calendarIdentifier)
                        if let index {
                            remindersData.calendarIdentifiersFilter.remove(at: index)
                        } else {
                            remindersData.calendarIdentifiersFilter.append(calendarIdentifier)
                        }
                    }) {
                        let isSelected = remindersData.calendarIdentifiersFilter.contains(calendarIdentifier)
                        SelectableView(title: calendar.title, isSelected: isSelected, color: Color(calendar.color))
                    }
                }
            }
        } label: {
            Image(systemName: "line.horizontal.3.decrease.circle")
        }
        .frame(width: 28)
        .modifier(ToolbarButtonModifier())
        .help(rmbLocalized(.remindersFilterSelectionHelp))
    }
}

#Preview {
    SettingsBarFilterMenu()
        .environmentObject(RemindersData())
}
