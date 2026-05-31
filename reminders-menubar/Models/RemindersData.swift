import SwiftUI
import Combine
import EventKit

@MainActor
class RemindersData: ObservableObject {
    private var cancellationTokens: [AnyCancellable] = []
    private let previewService = MenuBarPreviewService()

    init() {
        addObservers()
        Task {
            await update()
        }
    }

    // swiftlint:disable:next function_body_length
    private func addObservers() {
        Publishers.MergeMany(
            NotificationCenter.default.publisher(for: .EKEventStoreChanged),
            NotificationCenter.default.publisher(for: .NSCalendarDayChanged),
            NotificationCenter.default.publisher(for: .remindersDataShouldUpdate)
        )
        .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
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

        UserPreferences.shared.$menuBarCounterType
            .dropFirst()
            .sink { [weak self] _ in
                Task {
                    guard let self else { return }
                    self.updateMenuBarCount(to: await self.getMenuBarCount())
                }
            }
            .store(in: &cancellationTokens)

        UserPreferences.shared.$filterMenuBarContentByCalendar
            .dropFirst()
            .sink { [weak self] _ in
                Task {
                    guard let self else { return }
                    self.updateMenuBarCount(to: await self.getMenuBarCount())
                    await self.refreshPreview()
                }
            }
            .store(in: &cancellationTokens)

        UserPreferences.shared.$menuBarReminderPreviewEnabled
            .dropFirst()
            .sink { [weak self] _ in
                Task {
                    guard let self else { return }
                    await self.refreshPreview()
                }
            }
            .store(in: &cancellationTokens)

        Publishers.MergeMany(
            UserPreferences.shared.$reminderMenuBarIcon.map { _ in }.eraseToAnyPublisher(),
            UserPreferences.shared.$hideMenuBarIconWhenContentIsShown.map { _ in }.eraseToAnyPublisher()
        )
        .dropFirst()
        .sink { _ in
            AppDelegate.shared.loadMenuBarIcon()
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

        Publishers.MergeMany(
            $tagsFilter.removeDuplicates().map { _ in }.eraseToAnyPublisher(),
            UserPreferences.shared.$filterTagRemindersByCalendar.map { _ in }.eraseToAnyPublisher()
        )
        .dropFirst()
        .sink { [weak self] _ in
            Task {
                guard let self else { return }
                self.filteredTagReminderLists = await self.getTagReminders()
            }
        }
        .store(in: &cancellationTokens)
    }

    @Published var availableCalendars: [EKCalendar] = []

    @Published var availableTags: [Tag] = []

    @Published var upcomingReminders: [ReminderItem] = []

    @Published private var filteredReminderLists: [ReminderList] = []

    @Published private var filteredTagReminderLists: [TagReminderList] = []

    var orderedFilteredSections: [ReminderListSection] {
        let calendarSections = filteredReminderLists.map { ReminderListSection.calendar($0) }
        let tagSections = filteredTagReminderLists.map { ReminderListSection.tag($0) }

        if UserPreferences.shared.showTagsBeforeCalendars {
            return tagSections + calendarSections
        }
        return calendarSections + tagSections
    }

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

    @Published var tagsFilter: [Tag] = {
        return (UserPreferences.shared.preferredTagsFilter ?? []).map { Tag($0) }
    }() {
        didSet {
            UserPreferences.shared.preferredTagsFilter = tagsFilter.map(\.name)
        }
    }

    @Published var calendarForSaving: EKCalendar? = {
        guard RemindersService.shared.isAuthorized else {
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
        // Validate filter — remove stale calendars that no longer exist
        let calendars = RemindersService.shared.getCalendars()
        let calendarsSet = Set(calendars.map({ $0.calendarIdentifier }))
        self.availableCalendars = calendars
        self.calendarIdentifiersFilter = self.calendarIdentifiersFilter.filter({ calendarsSet.contains($0) })
        CalendarParser.updateShared(with: calendars)

        // Validate filter — remove stale tags that no longer exist
        if #available(macOS 12, *) {
            let tags = await RemindersService.shared.getAllTags()
            self.availableTags = tags
            self.tagsFilter = self.tagsFilter.filter({ tags.contains($0) })
            TagParser.updateShared(with: tags)
        }

        // Fetch reminder data with validated filters
        self.filteredReminderLists = await RemindersService.shared.getReminders(of: self.calendarIdentifiersFilter)
        self.upcomingReminders = await getUpcomingReminders()
        self.filteredTagReminderLists = await getTagReminders()

        // Update menu bar
        self.updateMenuBarCount(to: await getMenuBarCount())
        await self.refreshPreview()

        // Update search data
        if showingRecentReminders {
            self.recentReminders = await fetchRecentReminders()
        }
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

    private func getTagReminders() async -> [TagReminderList] {
        guard #available(macOS 12, *) else { return [] }
        guard !tagsFilter.isEmpty else { return [] }

        let calendarFilter = UserPreferences.shared.filterTagRemindersByCalendar
            ? self.calendarIdentifiersFilter
            : nil

        return await RemindersService.shared.getReminders(
            byTags: self.tagsFilter,
            calendarIdentifiers: calendarFilter
        )
    }

    private func fetchRecentReminders() async -> [ReminderItem] {
        return await RemindersService.shared.getRecentReminders()
    }

    private func getMenuBarCount() async -> Int {
        let calendarFilter = UserPreferences.shared.filterMenuBarContentByCalendar
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

    private func updateMenuBarCount(to count: Int) {
        AppDelegate.shared.updateMenuBarCount(to: count)
    }

    private func refreshPreview() async {
        let calendarFilter = UserPreferences.shared.filterMenuBarContentByCalendar
            ? calendarIdentifiersFilter
            : nil
        await previewService.refresh(calendarFilter: calendarFilter)
    }
}
