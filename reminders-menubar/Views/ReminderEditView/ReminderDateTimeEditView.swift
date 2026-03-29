import SwiftUI

struct ReminderDateTimeEditView: View {
    @Binding var date: Date
    let components: RmbDatePicker.DatePickerComponents
    @Binding var hasComponent: Bool

    private var isTime: Bool { components == .time }
    private var pickerIcon: String { isTime ? "clock" : "calendar" }
    private var addButtonText: String {
        rmbLocalized(isTime ? .newReminderAddTimeButton : .newReminderAddDateButton)
    }

    var body: some View {
        HStack {
            Image(systemName: pickerIcon)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .frame(width: 20)

            if hasComponent {
                RmbDatePicker(selection: $date, components: components)
                    .font(.systemFont(ofSize: 12, weight: .light))
                    .frame(width: 80)
                    .fixedSize(horizontal: true, vertical: true)

                Button {
                    hasComponent = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.borderless)
            } else {
                Button {
                    hasComponent = true
                } label: {
                    Text(addButtonText)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.borderless)
            }
        }
        .frame(height: 20)
    }
}

#Preview {
    let date = Date()

    ReminderDateTimeEditView(date: .constant(date), components: .date, hasComponent: .constant(false))
    ReminderDateTimeEditView(date: .constant(date), components: .time, hasComponent: .constant(false))

    ReminderDateTimeEditView(date: .constant(date), components: .date, hasComponent: .constant(true))
    ReminderDateTimeEditView(date: .constant(date), components: .time, hasComponent: .constant(true))
}
