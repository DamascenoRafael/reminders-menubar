import SwiftUI

struct ToolbarView: View {
    @EnvironmentObject var remindersData: RemindersData

    var body: some View {
        HStack(spacing: 4) {
            CreateReminderButton()
                .disabled(remindersData.availableCalendars.isEmpty)

            Spacer()
            
            SearchRemindersButton()
                .disabled(remindersData.availableCalendars.isEmpty)

            RecentRemindersButton()
                .disabled(remindersData.availableCalendars.isEmpty)

            FilterReminderListButton()
                .disabled(remindersData.availableCalendars.isEmpty)

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
