import SwiftUI

struct ReminderFlagUrgentEditView: View {
    @Binding var isFlagged: Bool
    @Binding var isUrgent: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(rmbSymbol: .pin)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .frame(width: 20)

            toggleButton(
                label: rmbLocalized(.editReminderFlaggedOption),
                symbol: isFlagged ? .flagFill : .flag,
                isActive: isFlagged,
                activeColor: .orange
            ) {
                isFlagged.toggle()
            }

            if #available(macOS 26, *) {
                toggleButton(
                    label: rmbLocalized(.editReminderUrgentOption),
                    symbol: .alarm,
                    isActive: isUrgent,
                    activeColor: .purple
                ) {
                    isUrgent.toggle()
                }
            }
        }
    }

    @ViewBuilder
    private func toggleButton(
        label: String,
        symbol: RmbSymbol,
        isActive: Bool,
        activeColor: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(rmbSymbol: symbol)
                Text(label)
            }
            .font(.system(size: 11))
            .foregroundColor(isActive ? activeColor : nil)
            .frame(height: 20)
            .padding(.horizontal, 8)
        }
        .buttonStyle(.borderless)
        .background(isActive ? activeColor.opacity(0.15) : Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

#Preview {
    VStack {
        ReminderFlagUrgentEditView(isFlagged: .constant(false), isUrgent: .constant(false))
        ReminderFlagUrgentEditView(isFlagged: .constant(true), isUrgent: .constant(false))
        ReminderFlagUrgentEditView(isFlagged: .constant(true), isUrgent: .constant(true))
    }
    .padding()
}
