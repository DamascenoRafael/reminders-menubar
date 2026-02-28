import SwiftUI
import EventKit

// MARK: - Search filter environment

private struct SearchFilterWordsKey: EnvironmentKey {
    static let defaultValue: [String] = []
}

extension EnvironmentValues {
    var searchFilterWords: [String] {
        get { self[SearchFilterWordsKey.self] }
        set { self[SearchFilterWordsKey.self] = newValue }
    }
}

struct ContentView: View {
    @EnvironmentObject var remindersData: RemindersData
    @ObservedObject var userPreferences = UserPreferences.shared
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    @State private var searchFilterText = ""

    /// Returns the search words to use for filtering, or empty if no visible item matches
    /// (when nothing matches, filtering is disabled so all items appear normally).
    private var effectiveSearchWords: [String] {
        let trimmed = searchFilterText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return [] }
        let words = trimmed.lowercased().split(separator: " ").map(String.init)

        let isShowingCompleted = !userPreferences.showUncompletedOnly
        var visibleReminders = remindersData.filteredReminderLists.flatMap { list -> [ReminderItem] in
            var items = list.reminders.uncompleted
            if isShowingCompleted {
                items += list.reminders.completed
            }
            return items + items.flatMap { collectChildren($0) }
        }
        if userPreferences.showUpcomingReminders {
            visibleReminders += remindersData.upcomingReminders
        }

        let anyMatch = visibleReminders.contains { item in
            let title = item.reminder.title.lowercased()
            return words.allSatisfy { title.contains($0) }
        }

        return anyMatch ? words : []
    }

    private func collectChildren(_ item: ReminderItem) -> [ReminderItem] {
        let children = item.childReminders.uncompleted + item.childReminders.completed
        return children + children.flatMap { collectChildren($0) }
    }

    var body: some View {
        VStack(spacing: 0) {
            FormNewReminderView(searchFilterText: $searchFilterText)

            if userPreferences.atLeastOneFilterIsSelected {
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
                            let uncompletedIsEmpty = reminderList.reminders.uncompleted.isEmpty
                            let completedIsEmpty = reminderList.reminders.completed.isEmpty
                            let calendarIsEmpty = uncompletedIsEmpty && completedIsEmpty
                            let isShowingCompleted = !userPreferences.showUncompletedOnly
                            let viewIsEmpty = isShowingCompleted ? calendarIsEmpty : uncompletedIsEmpty
                            if viewIsEmpty {
                                NoReminderItemsView(emptyList: calendarIsEmpty ? .noReminders : .allItemsCompleted)
                            }
                            ForEach(reminderList.reminders.uncompleted) { reminderItem in
                                ReminderItemView(reminderItem: reminderItem, isShowingCompleted: isShowingCompleted)
                            }
                            if isShowingCompleted {
                                ForEach(reminderList.reminders.completed) { reminderItem in
                                    ReminderItemView(reminderItem: reminderItem, isShowingCompleted: isShowingCompleted)
                                }
                            }
                        }
                        .modifier(ListSectionSpacing())
                        .modifier(ListRowSeparatorHidden())
                    }
                }
                .listStyle(.plain)
                .animation(.default, value: remindersData.filteredReminderLists)
                .environment(\.searchFilterWords, effectiveSearchWords)
            } else {
                VStack(spacing: 4) {
                    Text(rmbLocalized(.emptyListNoRemindersFilterTitle))
                        .multilineTextAlignment(.center)
                    Text(rmbLocalized(.emptyListNoRemindersFilterMessage))
                        .multilineTextAlignment(.center)
                }
                .frame(maxHeight: .infinity)
            }
            
            SettingsBarView()
        }
        .background(Color.rmbColor(for: .backgroundTheme, and: colorSchemeContrast).padding(-80))
        .preferredColorScheme(userPreferences.rmbColorScheme.colorScheme)
    }
}

struct ListSectionSpacing: ViewModifier {
    func body(content: Content) -> some View {
        return content
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 8, trailing: 0))
            .padding(.horizontal, 8)
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

 struct ContentView_Previews: PreviewProvider {
     static var previews: some View {
         ContentView().environmentObject(RemindersData())
     }
 }
