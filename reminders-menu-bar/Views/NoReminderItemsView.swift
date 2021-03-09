import SwiftUI
import EventKit

struct NoReminderItemsView: View {
    
    enum EmptyListType {
        case noReminders
        case allItemsCompleted
        
        var message: String {
            switch self {
            case .noReminders:
                return "No reminders"
            case .allItemsCompleted:
                return "All items completed"
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

struct EmptyCalendarView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ForEach(ColorScheme.allCases, id: \.self) { color in
                NoReminderItemsView(emptyList: .noReminders)
                    .colorScheme(color)
                    .previewDisplayName("\(color) mode")
            }
        }
    }
}
