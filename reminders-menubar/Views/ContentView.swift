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
            } else if remindersData.showingRecentReminders {
                List {
                    Section(header: RecentRemindersTitle()) {
                        RecentRemindersContent()
                    }
                    .modifier(ListSectionSpacing())
                    .modifier(ListRowSeparatorHidden())
                }
                .listStyle(.plain)
                .animation(.default, value: remindersData.recentReminders)
                .padding(.bottom, 10)
            } else if userPreferences.atLeastOneFilterIsSelected {
                List {
                    if userPreferences.showUpcomingReminders {
                        Section(header: UpcomingRemindersTitle()) {
                            UpcomingRemindersContent()
                        }
                        .modifier(ListSectionSpacing())
                        .modifier(ListRowSeparatorHidden())
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
                        .modifier(ListSectionSpacing())
                        .modifier(ListRowSeparatorHidden())
                    }
                }
                .listStyle(.plain)
                .animation(.default, value: remindersData.filteredReminderLists)
                .padding(.bottom, 10)
            } else {
                NoFilterSelectedView()
                    .frame(maxHeight: .infinity)
            }
        }
        .overlay(PopoverResizeHandleView().padding(4), alignment: .bottomTrailing)
        .modifier(RmbBackgroundModifier())
        .preferredColorScheme(userPreferences.rmbColorScheme.colorScheme)
        .environment(\.appHasPopoverOpen, $appHasPopoverOpen)
    }
}

struct ListSectionSpacing: ViewModifier {
    func body(content: Content) -> some View {
        return content
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 8, trailing: 0))
            .padding(.horizontal, 6)
    }
}

struct ListRowSeparatorHidden: ViewModifier {
    func body(content: Content) -> some View {
        if #available(macOS 14.0, *) {
            content
                .listRowSeparator(.hidden)
        } else {
            content
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(RemindersData())
}
