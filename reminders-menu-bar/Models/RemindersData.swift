import SwiftUI
import Combine
import EventKit

class RemindersData: ObservableObject {
    
    let userPreferences = UserPreferences.instance
    
    var cancellationTokens: [AnyCancellable] = []
    
    init() {
        addObservers()
        update()
    }
    
    private func addObservers() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(update),
                                               name: .EKEventStoreChanged,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(update),
                                               name: .NSCalendarDayChanged,
                                               object: nil)
        
        cancellationTokens.append(
            userPreferences.$showMenuBarTodayCount.dropFirst().sink { [weak self] showMenuBarTodayCount in
                self?.updateMenuBarTodayCount(showMenuBarTodayCount)
            }
        )
        
        cancellationTokens.append(
            userPreferences.$upcomingRemindersInterval.dropFirst().sink { [weak self] upcomingRemindersInterval in
                self?.upcomingReminders = RemindersService.instance.getUpcomingReminders(upcomingRemindersInterval)
            }
        )
        
        cancellationTokens.append(
            userPreferences.$calendarIdentifiersFilter.dropFirst().sink { [weak self] calendarIdentifiersFilter in
                self?.filteredReminderLists = RemindersService.instance.getReminders(of: calendarIdentifiersFilter)
            }
        )
    }
    
    @Published var calendars: [EKCalendar] = []
    
    @Published var upcomingReminders: [EKReminder] = []
    
    @Published var filteredReminderLists: [ReminderList] = []
    
    @objc func update() {
        // TODO: Prefer receive(on:options:) over explicit use of dispatch queues when performing work in subscribers.
        // https://developer.apple.com/documentation/combine/fail/receive(on:options:)
        DispatchQueue.main.async {
            let calendars = RemindersService.instance.getCalendars()
            self.calendars = calendars
            
            self.userPreferences.calendarIdentifiersFilter = self.userPreferences.calendarIdentifiersFilter.filter({
                RemindersService.instance.isValid(calendarIdentifier: $0)
            })
            if self.userPreferences.calendarIdentifiersFilter.isEmpty {
                self.userPreferences.calendarIdentifiersFilter = calendars.map({ $0.calendarIdentifier })
            }
            
            let calendarForSavingIdentifier = self.userPreferences.calendarForSaving.calendarIdentifier
            if !RemindersService.instance.isValid(calendarIdentifier: calendarForSavingIdentifier) {
                self.userPreferences.calendarForSaving = RemindersService.instance.getDefaultCalendar()
            }
            
            let upcomingRemindersInterval = self.userPreferences.upcomingRemindersInterval
            self.upcomingReminders = RemindersService.instance.getUpcomingReminders(upcomingRemindersInterval)
            
            self.updateMenuBarTodayCount(self.userPreferences.showMenuBarTodayCount)
        }
    }
    
    private func updateMenuBarTodayCount(_ showMenuBarTodayCount: Bool) {
        var todayCount = -1
        if showMenuBarTodayCount {
            todayCount = RemindersService.instance.getUpcomingReminders(.today).count
        }
        AppDelegate.instance.updateMenuBarTodayCount(to: todayCount)
    }
}
