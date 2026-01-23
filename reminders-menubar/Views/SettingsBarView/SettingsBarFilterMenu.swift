import SwiftUI
import EventKit

struct SettingsBarFilterMenu: View {
    @EnvironmentObject var remindersData: RemindersData
    @ObservedObject var userPreferences = UserPreferences.shared
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    
    @State var filterIsHovered = false
    @State private var eventCalendars: [EKCalendar] = []
    
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
                
                if !eventCalendars.isEmpty {
                    Divider()
                    
                    Text(rmbLocalized(.calendarEventsHeader))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ForEach(eventCalendars, id: \.calendarIdentifier) { calendar in
                        let calendarIdentifier = calendar.calendarIdentifier
                        Button(action: {
                            toggleEventCalendar(calendarIdentifier)
                        }) {
                            let isSelected = userPreferences.eventCalendarIdentifiersFilter.contains(calendarIdentifier)
                            SelectableView(title: calendar.title, isSelected: isSelected, color: Color(calendar.color))
                        }
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
        .onAppear {
            Task {
                await loadEventCalendars()
            }
        }
    }
    
    private func loadEventCalendars() async {
        let status = CalendarEventsService.shared.authorizationStatus()
        
        // Request access if not determined
        if status == .notDetermined {
            let granted = await CalendarEventsService.shared.requestAccess()
            if granted {
                eventCalendars = CalendarEventsService.shared.getEventCalendars()
            }
            return
        }
        
        // Check if authorized
        let isAuthorized: Bool
        if #available(macOS 14.0, *) {
            isAuthorized = status == .fullAccess
        } else {
            isAuthorized = status == .authorized
        }
        if isAuthorized {
            eventCalendars = CalendarEventsService.shared.getEventCalendars()
        }
    }
    
    private func toggleEventCalendar(_ calendarIdentifier: String) {
        // Toggle the calendar
        if let index = userPreferences.eventCalendarIdentifiersFilter.firstIndex(of: calendarIdentifier) {
            userPreferences.eventCalendarIdentifiersFilter.remove(at: index)
        } else {
            userPreferences.eventCalendarIdentifiersFilter.append(calendarIdentifier)
        }
    }
}

struct SettingsBarFilterMenu_Previews: PreviewProvider {
    static var previews: some View {
        SettingsBarFilterMenu()
    }
}
