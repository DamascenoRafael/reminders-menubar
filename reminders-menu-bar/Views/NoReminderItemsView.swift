import SwiftUI
import EventKit

struct NoReminderItemsView: View {
    
    var calendarIsEmpty: Bool
    
    var body: some View {
        HStack(alignment: .center) {
            Image(systemName: "tray")
            let noRemindersText = calendarIsEmpty ? "No reminders" : "All items completed"
            Text(noRemindersText)
        }
        .font(.callout)
        .padding(.leading, 0.5)
        .padding(.bottom, 4)
        .background(Color("backgroundTheme"))
    }
}

struct EmptyCalendarView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ForEach(ColorScheme.allCases, id: \.self) { color in
                NoReminderItemsView(calendarIsEmpty: true)
                    .colorScheme(color)
                    .previewDisplayName("\(color) mode")
            }
        }
    }
}
