import SwiftUI
import EventKit

struct ReminderListEditView: View {
    @EnvironmentObject var remindersData: RemindersData
    @Binding var selection: EKCalendar?

    var body: some View {
        HStack {
            Image(systemName: "folder")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .frame(width: 20)

            Picker(selection: $selection) {
                ForEach(remindersData.calendars, id: \.calendarIdentifier) { calendar in
                    ColoredDotTitle.text(calendar.title, color: Color(calendar.color))
                        .tag(calendar as EKCalendar?)
                }
            } label: {
                Text(verbatim: "")
            }
            .controlSize(.small)
            .labelsHidden()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    var calendar: EKCalendar {
        let calendar = EKCalendar(for: .reminder, eventStore: .init())
        calendar.color = .systemTeal
        calendar.title = "Reminders"
        return calendar
    }
    ReminderListEditView(selection: .constant(calendar))
        .environmentObject(RemindersData())
}
