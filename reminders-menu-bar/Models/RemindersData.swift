import SwiftUI
import EventKit

class RemindersData: ObservableObject {
    @Published var calendars: [EKCalendar] = []
    @Published var calendarIdentifiersFilter: [String] = []
    @Published var showUncompletedOnly = true
    
    func loadCalendars() {
        let calendars = RemindersService.instance.getCalendars()
        self.calendars = calendars
        if calendarIdentifiersFilter.isEmpty {
            calendarIdentifiersFilter = calendars.map({ $0.calendarIdentifier })
        }
    }
}
