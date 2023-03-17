import SwiftUI

struct SettingsBarFilterMenu: View {
    @EnvironmentObject var remindersData: RemindersData
    @ObservedObject var userPreferences = UserPreferences.shared
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    
    @State var filterIsHovered = false
    
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
                        let index = userPreferences.calendarIdentifiersFilter.firstIndex(of: calendarIdentifier)
                        if let index {
                            userPreferences.calendarIdentifiersFilter.remove(at: index)
                        } else {
                            userPreferences.calendarIdentifiersFilter.append(calendarIdentifier)
                        }
                    }) {
                        let isSelected = userPreferences.calendarIdentifiersFilter.contains(calendarIdentifier)
                        SelectableView(title: calendar.title, isSelected: isSelected, color: Color(calendar.color))
                    }
                }
            }
        } label: {
            Image(systemName: "line.horizontal.3.decrease.circle")
        }
        .menuStyle(BorderlessButtonMenuStyle())
        .frame(width: 32, height: 16)
        .padding(3)
        .background(filterIsHovered ? Color.rmbColor(for: .buttonHover, and: colorSchemeContrast) : nil)
        .cornerRadius(4)
        .onHover { isHovered in
            filterIsHovered = isHovered
        }
        .help(rmbLocalized(.remindersFilterSelectionHelp))
    }
}

struct SettingsBarFilterMenu_Previews: PreviewProvider {
    static var previews: some View {
        SettingsBarFilterMenu()
    }
}
