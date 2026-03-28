import SwiftUI
import EventKit

struct ReminderListEditView: View {
    let calendars: [EKCalendar]
    @Binding var selection: EKCalendar?

    var body: some View {
        HStack {
            Image(systemName: "folder")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .frame(width: 20)

            Picker(selection: $selection) {
                ForEach(calendars, id: \.calendarIdentifier) { calendar in
                    ColoredDotTitle.text(calendar.title, color: Color(calendar.color))
                        .tag(calendar as EKCalendar?)
                }
            } label: {
                Text(verbatim: "")
            }
            .labelsHidden()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
