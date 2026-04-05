import SwiftUI

struct ToolbarView: View {
    @EnvironmentObject var remindersData: RemindersData

    var body: some View {
        HStack(spacing: 4) {
            CreateReminderButton()
                .disabled(remindersData.calendars.isEmpty)

            Spacer()
            
            SearchRemindersButton()
                .disabled(remindersData.calendars.isEmpty)

            RecentRemindersButton()
                .disabled(remindersData.calendars.isEmpty)

            FilterReminderListButton()
                .disabled(remindersData.calendars.isEmpty)

            UpdateAvailableButton()

            OpenSettingButton()
        }
        .padding(.top, 10)
        .padding(.trailing, 10)
        .padding(.leading, 14)
        .padding(.bottom, 6)
    }
}

#Preview {
    ToolbarView()
        .environmentObject(RemindersData())
}
