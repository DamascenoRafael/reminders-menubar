import SwiftUI

struct CreateReminderButton: View {
    @Binding var showingCreateView: Bool

    var body: some View {
        Button {
            showingCreateView = true
        } label: {
            ToolbarButtonLabel {
                HStack {
                    Image(rmbSymbol: .plus)
                    Text(String("⌘N"))
                        .foregroundColor(.secondary)
                        .font(.footnote)
                }
                .padding(.trailing, 2)
            }
        }
        .keyboardShortcut("n", modifiers: .command)
        .modifier(ConfirmButtonModifier())
        .help(rmbLocalized(.newReminderButtonHelp))
    }
}

#Preview {
    CreateReminderButton(showingCreateView: .constant(false))
}
