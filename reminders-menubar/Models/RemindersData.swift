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
                let count = self?.getMenuBarCount(menuBarCounterType) ?? -1
                self?.updateMenuBarCount(with: count)
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
        let calendars = RemindersService.shared.getCalendars()
        
        let calendarsSet = Set(calendars.map({ $0.calendarIdentifier }))
        let calendarIdentifiersFilter = self.calendarIdentifiersFilter.filter({
            // NOTE: Checking if calendar in filter still exist
            calendarsSet.contains($0)
        })
        
        let upcomingRemindersInterval = self.userPreferences.upcomingRemindersInterval
        let upcomingReminders = RemindersService.shared.getUpcomingReminders(upcomingRemindersInterval)
        
        let menuBarCount = getMenuBarCount(self.userPreferences.menuBarCounterType)
        
        // TODO: Prefer receive(on:options:) over explicit use of dispatch queues when performing work in subscribers.
        // https://developer.apple.com/documentation/combine/fail/receive(on:options:)
        DispatchQueue.main.async {
            self.calendars = calendars
            self.calendarIdentifiersFilter = calendarIdentifiersFilter
            self.upcomingReminders = upcomingReminders
            self.updateMenuBarCount(with: menuBarCount)
        }
    }
    
    private func getMenuBarCount(_ menuBarCounterType: RmbMenuBarCounterType) -> Int {
        switch menuBarCounterType {
        case .today:
            return RemindersService.shared.getUpcomingReminders(.today).count
        case .allReminders:
            return RemindersService.shared.getAllRemindersCount()
        case .disabled:
            return -1
        }
    }
    
    private func updateMenuBarCount(with count: Int) {
        AppDelegate.shared.updateMenuBarTodayCount(to: count)
    }
}
