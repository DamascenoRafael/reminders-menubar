import SwiftUI
import Combine
import EventKit

@MainActor
class RemindersData: ObservableObject {
    private let userPreferences = UserPreferences.shared

    private var cancellationTokens: [AnyCancellable] = []

    init() {
        addObservers()
        Task {
            await update()
        }
    }

    private func addObservers() {
        NotificationCenter.default.publisher(for: .EKEventStoreChanged)
            .sink { [weak self] _ in
                Task {
                    await self?.update()
                }
            }
            .store(in: &cancellationTokens)

        NotificationCenter.default.publisher(for: .NSCalendarDayChanged)
            .sink { [weak self] _ in
                Task {
                    await self?.update()
                }
            }
            .store(in: &cancellationTokens)

        userPreferences.$menuBarCounterType
            .dropFirst()
            .sink { [weak self] menuBarCounterType in
                Task {
                    guard let self else { return }
                    let count = await self.getMenuBarCount(menuBarCounterType)
                    self.updateMenuBarCount(with: count)
                }
            }
            .store(in: &cancellationTokens)
        
        userPreferences.$filterRemindersCountByCalendar
            .dropFirst()
            .sink { [weak self] _ in
                Task {
                    guard let self else { return }
                    let count = await self.getMenuBarCount(self.userPreferences.menuBarCounterType)
                    self.updateMenuBarCount(with: count)
                }
            }
            .store(in: &cancellationTokens)

        userPreferences.$upcomingRemindersInterval
            .dropFirst()
            .sink { [weak self] _ in
                Task {
                    guard let self else { return }
                    self.upcomingReminders = await self.getFilteredUpcomingReminders()
                }
            }
            .store(in: &cancellationTokens)

        userPreferences.$filterUpcomingRemindersByCalendar
            .dropFirst()
            .sink { [weak self] _ in
                Task {
                    guard let self else { return }
                    
                    self.upcomingReminders = await self.getFilteredUpcomingReminders()
                }
            }
            .store(in: &cancellationTokens)

        $calendarIdentifiersFilter
            .dropFirst()
            .sink { [weak self] calendarIdentifiersFilter in
                Task {
                    guard let self else { return }
                    self.filteredReminderLists = await RemindersService.shared.getReminders(
                        of: calendarIdentifiersFilter
                    )

                    self.upcomingReminders = await self.getFilteredUpcomingReminders()
                }
            }
            .store(in: &cancellationTokens)
    }

    @Published var calendars: [EKCalendar] = []

    @Published var upcomingReminders: [ReminderItem] = []

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

    func update() async {
        let calendars = RemindersService.shared.getCalendars()

        let calendarsSet = Set(calendars.map({ $0.calendarIdentifier }))
        let calendarIdentifiersFilter = self.calendarIdentifiersFilter.filter({
            // NOTE: Checking if calendar in filter still exist
            calendarsSet.contains($0)
        })
        
        let upcomingReminders = await getFilteredUpcomingReminders()

        let menuBarCount = await getMenuBarCount(self.userPreferences.menuBarCounterType)

        self.calendars = calendars
        self.calendarIdentifiersFilter = calendarIdentifiersFilter
        self.upcomingReminders = upcomingReminders
        self.updateMenuBarCount(with: menuBarCount)
    }
    
    private func getFilteredUpcomingReminders() async -> [ReminderItem] {
        let shouldFilter = UserPreferences.shared.filterUpcomingRemindersByCalendar
        let filters = shouldFilter ? self.calendarIdentifiersFilter : nil

        let upcomingRemindersInterval = self.userPreferences.upcomingRemindersInterval
        let upcomingReminders = await RemindersService.shared.getUpcomingReminders(
            upcomingRemindersInterval,
            for: filters
        )
        
        return upcomingReminders
    }

    private func getMenuBarCount(_ menuBarCounterType: RmbMenuBarCounterType) async -> Int {
        let shouldFilter = UserPreferences.shared.filterRemindersCountByCalendar
        let filters = shouldFilter ? self.calendarIdentifiersFilter : nil
        
        switch menuBarCounterType {
        case .due:
            return await RemindersService.shared.getUpcomingReminders(.due, for: filters).count
        case .today:
            return await RemindersService.shared.getUpcomingReminders(.today, for: filters).count
        case .allReminders:
            return await RemindersService.shared.getUpcomingReminders(.all, for: filters).count
        case .disabled:
            return -1
        }
    }

    private func updateMenuBarCount(with count: Int) {
        AppDelegate.shared.updateMenuBarTodayCount(to: count)
    }
}
