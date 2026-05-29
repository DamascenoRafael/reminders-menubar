import SwiftUI

struct RecentRemindersButton: View {
    @EnvironmentObject var remindersData: RemindersData

    var body: some View {
        Button(action: {
            remindersData.showingRecentReminders.toggle()
        }) {
            ToolbarButtonLabel {
                Image(systemName: "clock.arrow.trianglehead.counterclockwise.rotate.90")
            }
        }
        .modifier(ToolbarButtonModifier())
        .background(
            remindersData.showingRecentReminders
                ? Color.rmbColor(.buttonHover)
                : nil
        )
        .cornerRadius(8)
        .help(rmbLocalized(.recentRemindersButtonHelp))
    }
}

#Preview {
    RecentRemindersButton()
        .environmentObject(RemindersData())
}
