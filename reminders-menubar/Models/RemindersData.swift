import SwiftUI
import Combine
import EventKit

class RemindersData: ObservableObject {
    private let userPreferences = UserPreferences.shared
    
    private var cancellationTokens: [AnyCancellable] = []
    
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
            userPreferences.$menuBarCounterType.dropFirst().sink { [weak self] menuBarCounterType in
                self?.updateMenuBarCount(menuBarCounterType)
            }
        )
        
        cancellationTokens.append(
            userPreferences.$upcomingRemindersInterval.dropFirst().sink { [weak self] upcomingRemindersInterval in
                self?.upcomingReminders = RemindersService.shared.getUpcomingReminders(upcomingRemindersInterval)
            }
        )
        
        cancellationTokens.append(
            $calendarIdentifiersFilter.dropFirst().sink { [weak self] calendarIdentifiersFilter in
                self?.filteredReminderLists = RemindersService.shared.getReminders(of: calendarIdentifiersFilter)
            }
        )
    }
    
    @Published var calendars: [EKCalendar] = []
    
    @Published var upcomingReminders: [EKReminder] = []
    
    @Published var filteredReminderLists: [ReminderList] = []
    
    @Published var calendarIdentifiersFilter: [String] = {
        guard let identifiers = UserPreferences.shared.preferredCalendarIdentifiersFilter else {
            // NOTE: On first use it will load all reminder lists.
            let calendars = RemindersService.shared.getCalendars()
            let allIdentifiers = calendars.map({ $0.calendarIdentifier })
            return allIdentifiers
        }
        
        return identifiers
    }() {
        didSet {
            UserPreferences.shared.preferredCalendarIdentifiersFilter = calendarIdentifiersFilter
        }
    }
    
    @Published var calendarForSaving: EKCalendar? = {
        guard RemindersService.shared.authorizationStatus() == .authorized else {
            return nil
        }
        
        guard let identifier = UserPreferences.shared.preferredCalendarIdentifierForSaving,
              let calendar = RemindersService.shared.getCalendar(withIdentifier: identifier) else {
            return RemindersService.shared.getDefaultCalendar()
        }
        
        return calendar
    }() {
        didSet {
            let identifier = calendarForSaving?.calendarIdentifier
            UserPreferences.shared.preferredCalendarIdentifierForSaving = identifier
        }
    }
    
    @objc func update() {
        // TODO: Prefer receive(on:options:) over explicit use of dispatch queues when performing work in subscribers.
        // https://developer.apple.com/documentation/combine/fail/receive(on:options:)
        DispatchQueue.main.async {
            let calendars = RemindersService.shared.getCalendars()
            self.calendars = calendars
            
            self.calendarIdentifiersFilter = self.calendarIdentifiersFilter.filter({
                RemindersService.shared.isValid(calendarIdentifier: $0)
            })
            
            let upcomingRemindersInterval = self.userPreferences.upcomingRemindersInterval
            self.upcomingReminders = RemindersService.shared.getUpcomingReminders(upcomingRemindersInterval)
            
            self.updateMenuBarCount(self.userPreferences.menuBarCounterType)
        }
    }
    
    private func updateMenuBarCount(_ menuBarCounterType: RmbMenuBarCounterType) {
        var count = -1
        if menuBarCounterType == .today {
            count = RemindersService.shared.getUpcomingReminders(.today).count
        } else if menuBarCounterType == .allReminders {
            count = RemindersService.shared.getAllRemindersCount()
        }
        AppDelegate.shared.updateMenuBarTodayCount(to: count)
    }
}
