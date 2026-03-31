import SwiftUI
import EventKit

struct NoReminderItemsView: View {
    enum EmptyListType {
        case noReminders
        case allItemsCompleted
        case noUpcomingReminders
        
        var message: String {
            switch self {
            case .noReminders:
                return rmbLocalized(.emptyListNoRemindersMessage)
            case .allItemsCompleted:
                return rmbLocalized(.emptyListAllItemsCompletedMessage)
            case .noUpcomingReminders:
                return rmbLocalized(.emptyListNoUpcomingRemindersMessage)
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
    NoReminderItemsView(emptyList: .noReminders)
    NoReminderItemsView(emptyList: .allItemsCompleted)
    NoReminderItemsView(emptyList: .noUpcomingReminders)
}
