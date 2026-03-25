import SwiftUI
import EventKit

struct ReminderPriorityEditView: View {
    @Binding var priority: EKReminderPriority

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.3")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .frame(width: 20)

            priorityButton(for: .none)
            priorityButton(for: .low)
            priorityButton(for: .medium)
            priorityButton(for: .high)
        }
    }

    @ViewBuilder
    private func priorityButton(for priority: EKReminderPriority) -> some View {
        let isSelected = self.priority == priority

        Button {
            self.priority = priority
        } label: {
            HStack {
                if let systemImage = priority.systemImage {
                    Image(systemName: systemImage)
                }
                Text(priority.title)
            }
            .font(.system(size: 11))
            .padding(.horizontal, 8)
        }
        .buttonStyle(.borderless)
        .frame(height: 20)
        .background(isSelected ? Color.accentColor.opacity(0.4) : Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
