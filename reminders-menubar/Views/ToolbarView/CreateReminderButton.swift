import SwiftUI

struct CreateReminderButton: View {
    @EnvironmentObject var remindersData: RemindersData
    @State private var showingCreateView = false

    var body: some View {
        Button {
            showingCreateView = true
        } label: {
            ToolbarButtonLabel {
                HStack {
                    Image(systemName: "plus")
                    Text(String("⌘N"))
                        .foregroundColor(.secondary)
                        .font(.footnote)
                }
                .padding(.trailing, 2)
            }
        }
        .keyboardShortcut("n", modifiers: .command)
        .modifier(ConfirmButtonModifier())
        .disabled(remindersData.calendars.isEmpty)
        .help(rmbLocalized(.newReminderButtonHelp))
        .sheet(isPresented: $showingCreateView) {
            ReminderEditView(isPresented: $showingCreateView)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSPopover.didCloseNotification)) { _ in
            showingCreateView = false
        }
    }
}

#Preview {
    CreateReminderButton()
}
