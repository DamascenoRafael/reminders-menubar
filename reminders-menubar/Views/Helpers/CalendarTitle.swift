import SwiftUI
import EventKit

struct CalendarTitle: View {
    var title: String
    var color: Color

    init(calendar: EKCalendar) {
        self.title = calendar.title
        self.color = Color(calendar.color)
    }

    init(title: String, color: Color) {
        self.title = title
        self.color = color
    }
    
    var body: some View {
        HStack(alignment: .center) {
            Text(title)
                .font(.headline)
                .foregroundColor(color)
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
