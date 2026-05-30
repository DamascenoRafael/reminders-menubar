import SwiftUI
import EventKit

struct CalendarTitle<Icon: View>: View {
    var title: String
    var color: Color
    var icon: Icon

    init(calendar: EKCalendar) where Icon == EmptyView {
        self.title = calendar.title
        self.color = Color(calendar.color)
        self.icon = EmptyView()
    }

    init(title: String, color: Color) where Icon == EmptyView {
        self.title = title
        self.color = color
        self.icon = EmptyView()
    }

    init(title: String, color: Color, @ViewBuilder icon: () -> Icon) {
        self.title = title
        self.color = color
        self.icon = icon()
    }
    
    var body: some View {
        HStack(alignment: .center) {
            Text(title)
                .font(.headline)
                .foregroundColor(color)
                .padding(.top, 2)
                .padding(.bottom, 5)

            icon
                .padding(.bottom, 3)

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
