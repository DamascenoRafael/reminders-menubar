import SwiftUI
import Combine
import EventKit

@MainActor
class RemindersData: ObservableObject {
    private var cancellationTokens: [AnyCancellable] = []

    init() {
        addObservers()
        Task {
            await update()
        }
    }

    private func addObservers() {
        Publishers.MergeMany(
            NotificationCenter.default.publisher(for: .EKEventStoreChanged),
            NotificationCenter.default.publisher(for: .NSCalendarDayChanged),
            NotificationCenter.default.publisher(for: .remindersDataShouldUpdate)
        )
        .sink { [weak self] _ in
            Task {
                await self?.update()
            }
        }
        .store(in: &cancellationTokens)

        Publishers.MergeMany(
            UserPreferences.shared.$showRemindersWithDueDateOnTop.map { _ in }.eraseToAnyPublisher(),
            UserPreferences.shared.$sortRemindersByPriority.map { _ in }.eraseToAnyPublisher(),
            UserPreferences.shared.$reminderSortingOrder.map { _ in }.eraseToAnyPublisher(),
            $calendarIdentifiersFilter.removeDuplicates().map { _ in }.eraseToAnyPublisher()
        )
        .dropFirst()
        .sink { [weak self] _ in
            Task {
                await self?.update()
            }
        }
        .store(in: &cancellationTokens)

        Publishers.MergeMany(
            UserPreferences.shared.$upcomingRemindersInterval.map { _ in }.eraseToAnyPublisher(),
            UserPreferences.shared.$filterUpcomingRemindersByCalendar.map { _ in }.eraseToAnyPublisher()
        )
        .dropFirst()
        .sink { [weak self] _ in
            Task {
                guard let self else { return }
                self.upcomingReminders = await self.getUpcomingReminders()
            }
        }
        .store(in: &cancellationTokens)

        Publishers.MergeMany(
            UserPreferences.shared.$menuBarCounterType.map { _ in }.eraseToAnyPublisher(),
            UserPreferences.shared.$filterMenuBarCountByCalendar.map { _ in }.eraseToAnyPublisher()
        )
        .dropFirst()
        .sink { [weak self] _ in
            Task {
                guard let self else { return }
                self.updateMenuBarCount(with: await self.getMenuBarCount())
            }
        }
        .store(in: &cancellationTokens)

        $searchText
            .dropFirst()
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .combineLatest($searchableReminders)
            .sink { [weak self] query, cached in
                guard let self else { return }
                guard showingSearch, !query.isEmpty, let cached else {
                    searchResults = nil
                    return
                }
                searchResults = RemindersService.shared.searchReminders(
                    matching: query,
                    in: cached
                )
            }
            .store(in: &cancellationTokens)
    }

    @Published var calendars: [EKCalendar] = []

    @Published var upcomingReminders: [ReminderItem] = []

    @Published var filteredReminderLists: [ReminderList] = []

    @Published var recentReminders: [ReminderItem]?

    @Published var showingRecentReminders: Bool = false {
        didSet {
            if showingRecentReminders {
                showingSearch = false
                Task {
                    self.recentReminders = await fetchRecentReminders()
                }
            } else {
                recentReminders = nil
            }
        }
    }

    @Published var showingSearch: Bool = false {
        didSet {
            if showingSearch {
                showingRecentReminders = false
                Task {
                    self.searchableReminders = await RemindersService.shared.fetchAllReminders()
                }
            } else {
                searchText = ""
                searchResults = nil
                searchableReminders = nil
            }
        }
    }

    @Published var searchText: String = ""

    @Published var searchResults: [ReminderItem]?

    @Published private var searchableReminders: [EKReminder]?

    @Published var calendarIdentifiersFilter: [String] = {
        guard let identifiers = UserPreferences.shared.preferredCalendarIdentifiersFilter else {
            // NOTE: On first use it will load all reminder lists.
            let allCalendars = RemindersService.shared.getCalendars()
            return allCalendars.map({ $0.calendarIdentifier })
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

        self.calendars = calendars
        self.calendarIdentifiersFilter = calendarIdentifiersFilter
        self.filteredReminderLists = await RemindersService.shared.getReminders(
            of: self.calendarIdentifiersFilter
        )
        self.upcomingReminders = await getUpcomingReminders()
        self.updateMenuBarCount(with: await getMenuBarCount())
    }
    
    private func getUpcomingReminders() async -> [ReminderItem] {
        let calendarFilter = UserPreferences.shared.filterUpcomingRemindersByCalendar
            ? self.calendarIdentifiersFilter
            : nil

        return await RemindersService.shared.getUpcomingReminders(
            UserPreferences.shared.upcomingRemindersInterval,
            for: calendarFilter
        )
    }

    private func fetchRecentReminders() async -> [ReminderItem] {
        return await RemindersService.shared.getRecentReminders()
    }

    private func getMenuBarCount() async -> Int {
        let calendarFilter = UserPreferences.shared.filterMenuBarCountByCalendar
            ? self.calendarIdentifiersFilter
            : nil
        
        switch UserPreferences.shared.menuBarCounterType {
        case .due:
            return await RemindersService.shared.getUpcomingReminders(.due, for: calendarFilter).count
        case .today:
            return await RemindersService.shared.getUpcomingReminders(.today, for: calendarFilter).count
        case .allReminders:
            return await RemindersService.shared.getUpcomingReminders(.all, for: calendarFilter).count
        case .disabled:
            return -1
        }
    }

    private func updateMenuBarCount(with count: Int) {
        AppDelegate.shared.updateMenuBarTodayCount(to: count)
    }
}
