import SwiftUI
import EventKit

struct ContentView: View {
    @EnvironmentObject var remindersData: RemindersData
    @ObservedObject var userPreferences = UserPreferences.shared
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                FormNewReminderView()

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
                    .modifier(ThinScrollBar())
                    .animation(.default, value: remindersData.filteredReminderLists)
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
            .modifier(ResponsiveTypeSize(isCompact: geometry.size.width < 300))
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

struct ResponsiveTypeSize: ViewModifier {
    let isCompact: Bool

    func body(content: Content) -> some View {
        if #available(macOS 12.0, *) {
            content
                .dynamicTypeSize(isCompact ? .xSmall : .small)
        } else {
            content
        }
    }
}

struct ThinScrollBar: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(ScrollViewConfigurator())
    }
}

struct ScrollViewConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let scrollView = view.enclosingScrollView {
                scrollView.scrollerStyle = .overlay
                scrollView.hasVerticalScroller = true
                scrollView.hasHorizontalScroller = false
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

 struct ContentView_Previews: PreviewProvider {
     static var previews: some View {
         ContentView().environmentObject(RemindersData())
     }
 }
