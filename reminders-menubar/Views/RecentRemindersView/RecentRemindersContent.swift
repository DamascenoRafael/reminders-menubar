import SwiftUI

struct RecentRemindersContent: View {
    @EnvironmentObject var remindersData: RemindersData

    private static let paginationBatchSize = 50
    @State private var displayCount = paginationBatchSize

    var body: some View {
        Group {
            if let recentReminders = remindersData.recentReminders {
                mainRecentRemindersContent(recentReminders)
            } else {
                HStack(alignment: .center) {
                    ProgressView()
                        .controlSize(.small)
                    Text(rmbLocalized(.recentRemindersLoadingMessage))
                }
                .font(.callout)
            }
        }
        .onChange(of: remindersData.recentReminders) { _ in
            displayCount = Self.paginationBatchSize
        }
    }

    @ViewBuilder
    private func mainRecentRemindersContent(_ recentReminders: [ReminderItem]) -> some View {
        if recentReminders.isEmpty {
            NoReminderItemsView(emptyList: .noRecentReminders)
        }

        ForEach(Array(recentReminders.prefix(displayCount))) { reminderItem in
            ReminderItemView(
                reminderItem: reminderItem,
                showCalendarTitle: true
            )
        }

        if displayCount < recentReminders.count {
            Button(action: {
                displayCount += Self.paginationBatchSize
            }) {
                Text(rmbLocalized(.recentRemindersShowMoreButton))
                    .font(.callout)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .buttonStyle(.borderless)
            .padding(.vertical, 4)
        }
    }
}

#Preview {
    RecentRemindersContent()
        .environmentObject(RemindersData())
        .environmentObject(CopyShortcutCoordinator())
}
