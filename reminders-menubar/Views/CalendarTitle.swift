import SwiftUI
import EventKit

struct CalendarTitle: View {
    var calendar: EKCalendar
    
    var body: some View {
        HStack(alignment: .center) {
            Text(calendar.title)
                .font(.headline)
                .foregroundColor(Color(calendar.color))
                .padding(.top, 2)
                .padding(.bottom, 5)
            
            Spacer()
        }
    }
}

#Preview {
    var calendar: EKCalendar {
        let calendar = EKCalendar(for: .reminder, eventStore: .init())
        calendar.title = "Reminders"
        calendar.color = .systemTeal
        return calendar
    }

    CalendarTitle(calendar: calendar)
}
