import SwiftUI
import EventKit

class RemindersData: ObservableObject {
    init () {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(update),
                                               name: .EKEventStoreChanged,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(update),
                                               name: .NSCalendarDayChanged,
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
        // TODO: Prefer receive(on:options:) over explicit use of dispatch queues when performing work in subscribers.
        // https://developer.apple.com/documentation/combine/fail/receive(on:options:)
        DispatchQueue.main.async {
            let calendars = RemindersService.instance.getCalendars()
            self.calendars = calendars
            self.calendarIdentifiersFilter = self.calendarIdentifiersFilter.filter({
                RemindersService.instance.isValid(calendarIdentifier: $0)
            })
            if self.calendarIdentifiersFilter.isEmpty {
                self.calendarIdentifiersFilter = calendars.map({ $0.calendarIdentifier })
            }
            if !RemindersService.instance.isValid(calendarIdentifier: self.calendarForSaving.calendarIdentifier) {
                self.calendarForSaving = RemindersService.instance.getDefaultCalendar()
            }
            self.filteredReminderLists = RemindersService.instance.getReminders(of: self.calendarIdentifiersFilter)
        }
    }
}
