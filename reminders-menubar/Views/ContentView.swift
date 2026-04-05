import SwiftUI
import EventKit

struct ContentView: View {
    @EnvironmentObject var remindersData: RemindersData
    @ObservedObject var userPreferences = UserPreferences.shared
    @State private var appHasPopoverOpen = false

    var body: some View {
        VStack(spacing: 0) {
            ToolbarView()

            if remindersData.calendars.isEmpty {
                NoReminderListsView()
                    .frame(maxHeight: .infinity)
            } else if remindersData.showingSearch {
                SearchBarView()

                List {
                    Section {
                        SearchRemindersContent()
                    }
                    .modifier(ListSectionModifier())
                }
                .modifier(ReminderListModifier(animationValue: remindersData.searchResults))
            } else if remindersData.showingRecentReminders {
                List {
                    Section(header: RecentRemindersTitle()) {
                        RecentRemindersContent()
                    }
                    .modifier(ListSectionModifier())
                }
                .modifier(ReminderListModifier(animationValue: remindersData.recentReminders))
            } else if userPreferences.atLeastOneFilterIsSelected {
                List {
                    if userPreferences.showUpcomingReminders {
                        Section(header: UpcomingRemindersTitle()) {
                            UpcomingRemindersContent()
                        }
                        .modifier(ListSectionModifier())
                    }
                    ForEach(remindersData.filteredReminderLists) { reminderList in
                        Section(header: CalendarTitle(calendar: reminderList.calendar)) {
                            if reminderList.reminders.isEmpty {
                                NoReminderItemsView(emptyList: .allItemsCompleted)
                            }
                            ForEach(reminderList.reminders) { reminderItem in
                                ReminderItemView(reminderItem: reminderItem)
                            }
                        }
                        .modifier(ListSectionModifier())
                    }
                }
                .modifier(ReminderListModifier(animationValue: remindersData.filteredReminderLists))
            } else {
                NoFilterSelectedView()
                    .frame(maxHeight: .infinity)
            }
        }
        .overlay(PopoverResizeHandleView().padding(4), alignment: .bottomTrailing)
        .modifier(RmbBackgroundModifier())
        .preferredColorScheme(userPreferences.rmbColorScheme.colorScheme)
        .environment(\.appHasPopoverOpen, $appHasPopoverOpen)
        .onReceive(NotificationCenter.default.publisher(for: NSPopover.didCloseNotification)) { _ in
            remindersData.showingSearch = false
            remindersData.showingRecentReminders = false
        }
    }
}

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
    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(macOS 13.0, *) {
            content
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 8, trailing: 0))
                .padding(.horizontal, 6)
                .listRowSeparator(.hidden)
        } else {
            content
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 8, trailing: 0))
                .padding(.horizontal, 6)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(RemindersData())
}
