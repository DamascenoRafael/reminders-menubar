import SwiftUI
import EventKit

class RemindersData: ObservableObject {
    @Published var calendars: [EKCalendar] = []
    
    @Published var calendarIdentifiersFilter = UserPreferences.instance.calendarIdentifiersFilter {
        didSet {
            UserPreferences.instance.calendarIdentifiersFilter = calendarIdentifiersFilter
        }
    }
    
    @Published var calendarForSaving = UserPreferences.instance.calendarForSaving {
        didSet {
            UserPreferences.instance.calendarForSaving = calendarForSaving
        }
    }
    
    @Published var showUncompletedOnly = UserPreferences.instance.showUncompletedOnly {
        didSet {
            UserPreferences.instance.showUncompletedOnly = showUncompletedOnly
        }
    }
    
    func loadCalendars() {
        let calendars = RemindersService.instance.getCalendars()
        self.calendars = calendars
        if calendarIdentifiersFilter.isEmpty {
            calendarIdentifiersFilter = calendars.map({ $0.calendarIdentifier })
        }
    }
}
