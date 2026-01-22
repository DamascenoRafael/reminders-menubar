import SwiftUI
import EventKit

struct NewReminderInfoOptionsView: View {
    @Binding var date: Date
    @Binding var hasDueDate: Bool
    @Binding var hasTime: Bool
    @Binding var priority: EKReminderPriority
    
    enum InfoOptionType {
        case date
        case time
        case priority
    }
    
    var body: some View {
        let infoOptions: [InfoOptionType] = [
            .date,
            hasDueDate ? .time : nil,
            .priority
        ].compactMap { $0 }
        
        let columns = 2
        let infoOptionsHStacked: [[InfoOptionType]] = stride(from: 0, to: infoOptions.count, by: columns).map {
            Array(infoOptions[$0..<min($0 + columns, infoOptions.count)])
        }
        
        VStack(alignment: .leading) {
            ForEach(infoOptionsHStacked, id: \.self) { optionsRow in
                HStack {
                    ForEach(optionsRow, id: \.self) { option in
                        singleInfoOptionView(for: option)
                            .modifier(ReminderInfoCapsule())
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    func singleInfoOptionView(for option: InfoOptionType) -> some View {
        switch option {
        case .date:
            reminderRemindDateTimeOptionView(date: $date, components: .date, hasComponent: $hasDueDate)
        case .time:
            reminderRemindDateTimeOptionView(date: $date, components: .time, hasComponent: $hasTime)
        case .priority:
            reminderPriorityOptionView(priority: $priority)
        }
    }
}

@ViewBuilder
func reminderRemindDateTimeOptionView(
    date: Binding<Date>,
    components: RmbDatePicker.DatePickerComponents,
    hasComponent: Binding<Bool>
) -> some View {
    let pickerIcon = components == .time ? "clock" : "calendar"
    
    let addTimeButtonText = rmbLocalized(.newReminderAddTimeButton)
    let addDateButtonText = rmbLocalized(.newReminderAddDateButton)
    let pickerAddComponentText = components == .time ? addTimeButtonText : addDateButtonText
    
    if hasComponent.wrappedValue {
        HStack {
            Image(systemName: pickerIcon)
                .font(.system(size: 12))
            RmbDatePicker(selection: date, components: components)
                .font(.systemFont(ofSize: 12, weight: .light))
                .fixedSize(horizontal: true, vertical: true)
                .padding(.top, 2)
            Button {
                hasComponent.wrappedValue = false
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12))
            }
            .buttonStyle(.borderless)
            .frame(width: 5, height: 5, alignment: .center)
        }
    } else {
        Button {
            hasComponent.wrappedValue = true
        } label: {
            Label(pickerAddComponentText, systemImage: pickerIcon)
                .font(.system(size: 12))
        }
        .buttonStyle(.borderless)
    }
}

private func priorityLabel(_ priority: EKReminderPriority) -> RemindersMenuBarLocalizedKeys {
    switch priority {
    case .low:
        return .editReminderPriorityLowOption
    case .medium:
        return .editReminderPriorityMediumOption
    case .high:
        return .editReminderPriorityHighOption
    default:
        return .changeReminderPriorityMenuOption
    }
}

@ViewBuilder
func reminderPriorityOptionView(priority: Binding<EKReminderPriority>) -> some View {
    let pickerIcon = priority.wrappedValue.systemImage ?? "exclamationmark.circle"
    
    Button {
        priority.wrappedValue = priority.wrappedValue.nextPriority
    } label: {
        Label(rmbLocalized(priorityLabel(priority.wrappedValue)), systemImage: pickerIcon)
            .font(.system(size: 12))
    }
    .buttonStyle(.borderless)
}

struct ReminderInfoCapsule: ViewModifier {
    func body(content: Content) -> some View {
        return content
            .frame(height: 20)
            .padding(.horizontal, 8)
            .background(Color.secondary.opacity(0.2))
            .clipShape(Capsule())
    }
}

#Preview {
    NewReminderInfoOptionsView(
        date: .constant(Date()),
        hasDueDate: .constant(true),
        hasTime: .constant(true),
        priority: .constant(.medium)
    )
}
