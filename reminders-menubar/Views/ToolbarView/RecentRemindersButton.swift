import SwiftUI

struct RecentRemindersButton: View {
    @EnvironmentObject var remindersData: RemindersData
    @ObservedObject var userPreferences = UserPreferences.shared
    
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
                ? Color.rmbColor(
                    for: .buttonHover,
                    isTransparencyEnabled: userPreferences.isTransparencyEnabled
                )
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
