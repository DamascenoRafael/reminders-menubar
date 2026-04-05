import SwiftUI

struct SearchRemindersContent: View {
    @EnvironmentObject var remindersData: RemindersData

    private static let paginationBatchSize = 50
    @State private var displayCount = paginationBatchSize

    var body: some View {
        Group {
            if remindersData.searchText.isEmpty {
                NoReminderItemsView(emptyList: .noSearchQuery)
            } else if let searchResults = remindersData.searchResults {
                mainSearchContent(searchResults)
            } else {
                ReminderLoadingView(message: rmbLocalized(.searchRemindersLoadingMessage))
            }
        }
        .onChange(of: remindersData.searchResults) { _ in
            displayCount = Self.paginationBatchSize
        }
    }

    @ViewBuilder
    private func mainSearchContent(_ searchResults: [ReminderItem]) -> some View {
        if searchResults.isEmpty {
            NoReminderItemsView(emptyList: .noSearchResults)
        }

        ForEach(Array(searchResults.prefix(displayCount))) { reminderItem in
            ReminderItemView(
                reminderItem: reminderItem,
                showCalendarTitle: true
            )
        }

        if displayCount < searchResults.count {
            ShowMoreRemindersButton {
                displayCount += Self.paginationBatchSize
            }
        }
    }
}

#Preview {
    SearchRemindersContent()
        .environmentObject(RemindersData())
}
