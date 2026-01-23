import SwiftUI

struct UpcomingRemindersTitle: View {
    @ObservedObject var userPreferences = UserPreferences.shared
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    @State var intervalButtonIsHovered = false

    var body: some View {
        HStack(alignment: .center) {
            Spacer()

            Menu {
                ForEach(ReminderInterval.allCases, id: \.rawValue) { interval in
                    Button(action: { userPreferences.upcomingRemindersInterval = interval }) {
                        let isSelected = interval == userPreferences.upcomingRemindersInterval
                        SelectableView(title: interval.title, isSelected: isSelected)
                    }
                }

                Divider()

                Button(action: {
                    userPreferences.filterUpcomingRemindersByCalendar.toggle()
                }) {
                    SelectableView(
                        title: rmbLocalized(.filterUpcomingRemindersByCalendarOptionButton),
                        isSelected: userPreferences.filterUpcomingRemindersByCalendar
                    )
                }
            } label: {
                Label(userPreferences.upcomingRemindersInterval.title, systemImage: "calendar")
                    .font(.caption2)
            }
            .menuStyle(BorderlessButtonMenuStyle())
            .padding(.vertical, 2)
            .padding(.horizontal, 4)
            .background(intervalButtonIsHovered ? Color.rmbColor(for: .buttonHover, and: colorSchemeContrast) : nil)
            .cornerRadius(3)
            .onHover { isHovered in
                intervalButtonIsHovered = isHovered
            }
            .fixedSize(horizontal: true, vertical: true)
            .help(rmbLocalized(.upcomingRemindersIntervalSelectionHelp))
        }
    }
}

struct UpcomingRemindersTitle_Previews: PreviewProvider {
    static var previews: some View {
        UpcomingRemindersTitle()
    }
}
