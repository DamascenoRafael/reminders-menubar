import SwiftUI
import EventKit

struct NoReminderItemsView: View {
    enum EmptyListType {
        case allItemsCompleted
        case noUpcomingReminders
        case noRecentReminders
        case noSearchQuery
        case noSearchResults
        
        var message: String {
            switch self {
            case .allItemsCompleted:
                return rmbLocalized(.emptyListAllItemsCompletedMessage)
            case .noUpcomingReminders:
                return rmbLocalized(.emptyListNoUpcomingRemindersMessage)
            case .noRecentReminders:
                return rmbLocalized(.emptyListNoRecentRemindersMessage)
            case .noSearchQuery:
                return rmbLocalized(.emptyListSearchNoQueryMessage)
            case .noSearchResults:
                return rmbLocalized(.emptyListSearchNoResultsMessage)
            }
        }
    }
    
    var emptyList: EmptyListType
    
    var body: some View {
        HStack(alignment: .center) {
            Image(systemName: "tray")
            Text(emptyList.message)
        }
        .font(.callout)
        .padding(.leading, 0.5)
        .padding(.bottom, 4)
    }
}

#Preview {
    NoReminderItemsView(emptyList: .allItemsCompleted)
    NoReminderItemsView(emptyList: .noUpcomingReminders)
    NoReminderItemsView(emptyList: .noRecentReminders)
}
