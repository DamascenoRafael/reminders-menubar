import SwiftUI

struct RecentRemindersButton: View {
    @EnvironmentObject var remindersData: RemindersData

    var body: some View {
        Button(action: {
            remindersData.showingRecentReminders.toggle()
        }) {
            ToolbarButtonLabel {
                Image(rmbSymbol: .recentReminders)
            }
        }
        .modifier(ToolbarButtonModifier(isActive: remindersData.showingRecentReminders))
        .help(rmbLocalized(.recentRemindersButtonHelp))
    }
}

#Preview {
    RecentRemindersButton()
        .environmentObject(RemindersData())
}
