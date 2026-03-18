import SwiftUI

struct UpcomingRemindersTitle: View {
    @ObservedObject var userPreferences = UserPreferences.shared

    var body: some View {
        HStack {
            CalendarTitle(title: userPreferences.upcomingRemindersInterval.sectionTitle, color: .red)
                .fixedSize()

            if userPreferences.filterUpcomingRemindersByCalendar {
                Image(systemName: "line.horizontal.3.decrease.circle")
                    .padding(.bottom, 3)
                    .help(rmbLocalized(.upcomingRemindersFilterByCalendarEnabledHelp))

                Spacer()
            }
        }
    }
}

#Preview {
    UpcomingRemindersTitle()
}
