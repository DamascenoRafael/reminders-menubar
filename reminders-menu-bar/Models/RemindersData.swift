import SwiftUI
import EventKit

class RemindersData: ObservableObject {
    init () {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(update),
                                               name: .EKEventStoreChanged,
                                               object: nil)
    }
    
    @Published var calendars: [EKCalendar] = []
    
    @Published var calendarIdentifiersFilter = UserPreferences.instance.calendarIdentifiersFilter {
        didSet {
            UserPreferences.instance.calendarIdentifiersFilter = calendarIdentifiersFilter
            filteredReminderLists = RemindersService.instance.getReminders(of: calendarIdentifiersFilter)
        }
    }
    
    @Published var filteredReminderLists: [ReminderList] = []
    
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
    
    @objc func update() {
        let calendars = RemindersService.instance.getCalendars()
        self.calendars = calendars
        if calendarIdentifiersFilter.isEmpty {
            calendarIdentifiersFilter = calendars.map({ $0.calendarIdentifier })
        }
        filteredReminderLists = RemindersService.instance.getReminders(of: calendarIdentifiersFilter)
    }
}
