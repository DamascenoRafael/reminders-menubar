import SwiftUI
import EventKit

struct ContentView: View {
    @EnvironmentObject var remindersData: RemindersData
    @ObservedObject var userPreferences = UserPreferences.shared
    @State private var appHasPopoverOpen = false
    @State private var escapeKeyMonitor: Any?
    @State private var showingCreateView = false
    @State private var pendingCreateTitle = ""

    var body: some View {
        VStack(spacing: 0) {
            ToolbarView(showingCreateView: $showingCreateView)

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
        .onAppear { startEscapeKeyMonitor() }
        .onDisappear { stopEscapeKeyMonitor() }
        .onReceive(
            NotificationCenter.default.publisher(
                for: NSPopover.didCloseNotification,
                object: AppDelegate.shared.popover
            )
        ) { _ in
            remindersData.showingSearch = false
            remindersData.showingRecentReminders = false
            showingCreateView = false
            pendingCreateTitle = ""
        }
        .onReceive(remindersData.createReminderPublisher) { title in
            if showingCreateView {
                pendingCreateTitle += title
            } else {
                pendingCreateTitle = title
                showingCreateView = true
            }
        }
        .sheet(isPresented: $showingCreateView, onDismiss: {
            pendingCreateTitle = ""
        }) {
            ReminderEditView(
                isPresented: $showingCreateView,
                initialTitle: pendingCreateTitle
            )
        }
    }

    // MARK: - Escape key handling

    private func startEscapeKeyMonitor() {
        guard escapeKeyMonitor == nil else { return }
        escapeKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [remindersData] event in
            let popoverWindow = AppDelegate.shared.popover.contentViewController?.view.window

            // When user types a printable character and no sheet/popover is open, open the create reminder sheet.
            if !appHasPopoverOpen,
               popoverWindow?.attachedSheet == nil,
               !FilterPanelController.shared.isVisible,
               let characters = event.charactersIgnoringModifiers,
               characters.count == 1,
               let scalar = characters.unicodeScalars.first,
               scalar.value >= 0x20, scalar.value <= 0x7E,
               !event.modifierFlags.contains(.command),
               !event.modifierFlags.contains(.option),
               !event.modifierFlags.contains(.control) {

                let typedText = event.characters ?? characters
                remindersData.createReminderPublisher.send(typedText)
                return nil
            }

            guard event.keyCode == RmbKeyCode.escape else { return event }
            // Let other UI layers (edit popovers, filter panel, sheets, alerts) handle their own escape
            guard !appHasPopoverOpen else { return event }
            guard !FilterPanelController.shared.isVisible else { return event }
            guard popoverWindow?.attachedSheet == nil else { return event }

            if remindersData.showingSearch {
                remindersData.showingSearch = false
                return nil
            }
            if remindersData.showingRecentReminders {
                remindersData.showingRecentReminders = false
                return nil
            }

            AppDelegate.shared.popover.performClose(nil)
            return nil
        }
    }

    private func stopEscapeKeyMonitor() {
        if let monitor = escapeKeyMonitor {
            NSEvent.removeMonitor(monitor)
            escapeKeyMonitor = nil
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
