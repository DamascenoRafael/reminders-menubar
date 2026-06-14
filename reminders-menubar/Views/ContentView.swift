import SwiftUI
import EventKit

struct ContentView: View {
    @EnvironmentObject var remindersData: RemindersData
    @ObservedObject var userPreferences = UserPreferences.shared
    @State private var appHasPopoverOpen = false
    @State private var keyMonitor: Any?

    var body: some View {
        VStack(spacing: 0) {
            ToolbarView()

            if remindersData.availableCalendars.isEmpty {
                emptyStateContent
            } else if remindersData.showingSearch {
                searchContent
            } else if remindersData.showingRecentReminders {
                recentRemindersContent
            } else if userPreferences.atLeastOneFilterIsSelected {
                filteredRemindersContent
            } else {
                noFilterContent
            }
        }
        .overlay(PopoverResizeHandleView().padding(4), alignment: .bottomTrailing)
        .modifier(RmbBackgroundModifier())
        .preferredColorScheme(userPreferences.rmbColorScheme.colorScheme)
        .environment(\.appHasPopoverOpen, $appHasPopoverOpen)
        .onAppear { startKeyMonitor() }
        .onDisappear { stopKeyMonitor() }
        .onReceive(
            NotificationCenter.default.publisher(
                for: NSPopover.didCloseNotification,
                object: AppDelegate.shared.popover
            )
        ) { _ in
            remindersData.showingSearch = false
            remindersData.showingRecentReminders = false
        }
    }

    // MARK: - Key handling

    private func startKeyMonitor() {
        guard keyMonitor == nil else { return }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard let popoverWindow = activePopoverWindow(for: event) else { return event }
            guard !appHasPopoverOpen else { return event }
            guard !FilterPanelController.shared.isVisible else { return event }

            if handlePrintableKey(event, popoverWindow: popoverWindow) {
                return nil
            }
            if handleEscapeKey(event, popoverWindow: popoverWindow) {
                return nil
            }
            return event
        }
    }

    private func activePopoverWindow(for event: NSEvent) -> NSWindow? {
        let popover = AppDelegate.shared.popover
        guard popover.isShown,
              let window = popover.contentViewController?.view.window,
              event.window === window else {
            return nil
        }
        return window
    }

    private func handlePrintableKey(_ event: NSEvent, popoverWindow: NSWindow) -> Bool {
        guard !remindersData.showingSearch,
              !remindersData.availableCalendars.isEmpty,
              popoverWindow.attachedSheet == nil || remindersData.pendingNewReminderTitle != nil,
              let typedText = printableText(from: event) else {
            return false
        }
        remindersData.pendingNewReminderTitle = (remindersData.pendingNewReminderTitle ?? "") + typedText
        return true
    }

    private func handleEscapeKey(_ event: NSEvent, popoverWindow: NSWindow) -> Bool {
        guard popoverWindow.attachedSheet == nil else { return false }
        guard event.keyCode == RmbKeyCode.escape else { return false }

        if remindersData.showingSearch {
            remindersData.showingSearch = false
            return true
        }
        if remindersData.showingRecentReminders {
            remindersData.showingRecentReminders = false
            return true
        }

        AppDelegate.shared.popover.performClose(nil)
        return true
    }

    private static let nonPrintableCategories: Set<Unicode.GeneralCategory> = [
        .control, .format, .surrogate, .privateUse, .unassigned
    ]

    private func printableText(from event: NSEvent) -> String? {
        let nonTypingModifiers: NSEvent.ModifierFlags = [.command, .control]
        guard event.modifierFlags.intersection(.deviceIndependentFlagsMask).isDisjoint(with: nonTypingModifiers),
              let characters = event.characters,
              !characters.isEmpty,
              characters.unicodeScalars.allSatisfy({
                  !Self.nonPrintableCategories.contains($0.properties.generalCategory)
              }) else {
            return nil
        }

        return characters
    }

    private func stopKeyMonitor() {
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }
    }

    // MARK: - Content subviews

    @ViewBuilder private var emptyStateContent: some View {
        NoReminderListsView()
            .frame(maxHeight: .infinity)
    }

    @ViewBuilder private var searchContent: some View {
        SearchBarView()

        List {
            Section {
                SearchRemindersContent()
            }
            .modifier(ListSectionModifier())
        }
        .modifier(ReminderListModifier(animationValue: remindersData.searchResults))
    }

    @ViewBuilder private var recentRemindersContent: some View {
        List {
            Section(header: CalendarTitle(
                title: rmbLocalized(.recentRemindersSectionTitle),
                color: .rmbColor(.recentSectionTitle),
                icon: {
                    Image(rmbSymbol: .recentReminders)
                }
            )) {
                RecentRemindersContent()
            }
            .modifier(ListSectionModifier())
        }
        .modifier(ReminderListModifier(animationValue: remindersData.recentReminders))
    }

    @ViewBuilder private var filteredRemindersContent: some View {
        List {
            if userPreferences.showUpcomingReminders {
                Section(header: CalendarTitle(
                    title: userPreferences.upcomingRemindersInterval.sectionTitle,
                    color: .rmbColor(.upcomingSectionTitle),
                    icon: {
                        if userPreferences.filterUpcomingRemindersByCalendar {
                            Image(rmbSymbol: .filterCircle)
                                .help(rmbLocalized(.upcomingRemindersFilterByCalendarEnabledHelp))
                        }
                    }
                )) {
                    UpcomingRemindersContent()
                }
                .modifier(ListSectionModifier())
            }

            ForEach(remindersData.orderedFilteredSections) { section in
                Section(header: CalendarTitle(
                    title: section.title,
                    color: section.color,
                    icon: {
                        if case .tag = section, userPreferences.filterTagRemindersByCalendar {
                            Image(rmbSymbol: .filterCircle)
                                .help(rmbLocalized(.tagRemindersFilterByCalendarEnabledHelp))
                        }
                    }
                )) {
                    if section.reminders.isEmpty {
                        NoReminderItemsView(emptyList: .allItemsCompleted)
                    }
                    ForEach(section.reminders) { reminderItem in
                        ReminderItemView(reminderItem: reminderItem)
                    }
                }
                .modifier(ListSectionModifier())
            }
        }
        .modifier(ReminderListModifier(animationValue: remindersData.orderedFilteredSections))
    }

    @ViewBuilder private var noFilterContent: some View {
        NoFilterSelectedView()
            .frame(maxHeight: .infinity)
    }
}

// MARK: - View Modifiers

struct ReminderListModifier<V: Equatable>: ViewModifier {
    let animationValue: V

    func body(content: Content) -> some View {
        content
            .listStyle(.plain)
            .animation(.default, value: animationValue)
            .padding(.bottom, 10)
    }
}

struct ListSectionModifier: ViewModifier {
    func body(content: Content) -> some View {
        let base = content
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 8, trailing: 0))
            .padding(.horizontal, 6)

        if #available(macOS 13.0, *) {
            base.listRowSeparator(.hidden)
        } else {
            base
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(RemindersData())
}
