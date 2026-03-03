import SwiftUI
import EventKit

struct CalendarTitle: View {
    var calendar: EKCalendar
    
    var body: some View {
        HStack(alignment: .center) {
            Text(calendar.title)
                .font(.headline)
                .foregroundColor(Color(calendar.color))
                .padding(.bottom, 5)
            
            Spacer()
        }
    }
}

struct CalendarTitleView_Previews: PreviewProvider {
    static var calendar: EKCalendar {
        let calendar = EKCalendar(for: .reminder, eventStore: .init())
        calendar.title = "Reminders"
        calendar.color = .systemTeal
        
        return calendar
    }
    
    static var previews: some View {
        Group {
            ForEach(ColorScheme.allCases, id: \.self) { color in
                CalendarTitle(calendar: calendar)
                    .colorScheme(color)
                    .previewDisplayName("\(color) mode")
            }
        }
    }
}
