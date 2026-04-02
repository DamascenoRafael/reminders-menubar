import SwiftUI

struct RecentRemindersTitle: View {
    var body: some View {
        HStack {
            CalendarTitle(title: rmbLocalized(.recentRemindersSectionTitle),color: .red)
                .fixedSize()

            Image(systemName: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                .padding(.bottom, 3)

            Spacer()
        }
    }
}

#Preview {
    RecentRemindersTitle()
}
