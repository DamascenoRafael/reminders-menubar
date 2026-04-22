import SwiftUI

struct ReminderRecurrenceEditView: View {
    @Binding var recurrence: RmbRecurrenceOption
    var isEnabled: Bool

    private static let selectableOptions: [RmbRecurrenceOption] = [
        .none, .daily, .weekly, .monthly, .yearly
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if recurrence == .custom {
                customRecurrenceRow()
            } else {
                pickerRow()
            }
        }
    }

    @ViewBuilder
    private func pickerRow() -> some View {
        HStack {
            Image(systemName: "repeat")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .frame(width: 20)

            Picker(selection: $recurrence) {
                ForEach(Self.selectableOptions, id: \.self) { option in
                    Text(option.title).tag(option)
                }
            } label: {
                Text(verbatim: "")
            }
            .controlSize(.small)
            .labelsHidden()
            .frame(maxWidth: .infinity, alignment: .leading)
            .disabled(!isEnabled)
            .opacity(isEnabled ? 1 : 0.5)
        }
    }

    @ViewBuilder
    private func customRecurrenceRow() -> some View {
        HStack {
            Image(systemName: "repeat")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .frame(width: 20)

            Text(RmbRecurrenceOption.custom.title)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .frame(minWidth: 80, alignment: .leading)

            Button {
                recurrence = .none
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.borderless)
        }
        .frame(height: 20)

        Text(rmbLocalized(.reminderRecurrenceCustomNote))
            .font(.system(size: 10))
            .foregroundColor(.secondary)
            .padding(.leading, 26)
    }
}

#Preview {
    ReminderRecurrenceEditView(recurrence: .constant(.none), isEnabled: true)
    ReminderRecurrenceEditView(recurrence: .constant(.daily), isEnabled: true)
    ReminderRecurrenceEditView(recurrence: .constant(.none), isEnabled: false)
    ReminderRecurrenceEditView(recurrence: .constant(.custom), isEnabled: true)
}
