import SwiftUI
import EventKit

struct CalendarTitle<Accessories: View>: View {
    let title: String
    let color: Color
    let accessories: Accessories

    init(calendar: EKCalendar) where Accessories == EmptyView {
        self.title = calendar.title
        self.color = Color(calendar.color)
        self.accessories = EmptyView()
    }

    init(title: String, color: Color) where Accessories == EmptyView {
        self.title = title
        self.color = color
        self.accessories = EmptyView()
    }

    init(title: String, color: Color, @ViewBuilder accessories: () -> Accessories) {
        self.title = title
        self.color = color
        self.accessories = accessories()
    }

    var body: some View {
        HStack(alignment: .center, spacing: 6) {
            Text(title)
                .font(.headline)
                .foregroundColor(color)
                .lineLimit(1)
                .truncationMode(.tail)

            HStack(spacing: 4) {
                accessories
            }
            .font(.caption)
            .fixedSize(horizontal: true, vertical: false)

            Spacer()
        }
        .padding(.top, 2)
        .padding(.bottom, 5)
    }
}

struct CalendarTitleIndicator: View {
    let symbol: RmbSymbol
    let helpText: String
    let text: String?

    init(symbol: RmbSymbol, helpText: String, text: String? = nil) {
        self.symbol = symbol
        self.helpText = helpText
        self.text = text
    }

    var body: some View {
        HStack(spacing: 2) {
            Image(rmbSymbol: symbol)
                .font(.system(size: 9))
            if let text {
                Text(text)
                    .font(.system(size: 9))
            }
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, 5)
        .padding(.vertical, 2)
        .background(
            Capsule()
                .fill(Color.secondary.opacity(0.08))
        )
        .help(helpText)
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
