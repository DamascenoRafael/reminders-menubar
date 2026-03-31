import SwiftUI

struct NoReminderListsView: View {
    private let appleRemindersUrl = URL(string: "x-apple-reminderkit://")

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.title)

            Text(rmbLocalized(.emptyListNoCalendarsTitle))
                .font(.headline)
                .multilineTextAlignment(.center)

            Text(rmbLocalized(.emptyListNoCalendarsMessage))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            if let appleRemindersUrl {
                Button(rmbLocalized(.openAppleRemindersButton)) {
                    NSWorkspace.shared.open(appleRemindersUrl)
                }
                .padding(.top, 6)
            }
        }
        .padding(.bottom, 36)
    }
}

#Preview {
    NoReminderListsView()
}
