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
        .onReceive(
            NotificationCenter.default.publisher(
                for: NSPopover.didCloseNotification,
                object: AppDelegate.shared.popover
            )
        ) { _ in
            resetCreateReminderSheetState()
        }
        .onChange(of: remindersData.pendingNewReminderTitle) { newValue in
            guard newValue != nil, !showingCreateView else { return }
            showingCreateView = true
        }
        .sheet(isPresented: $showingCreateView, onDismiss: resetCreateReminderSheetState) {
            ReminderEditView(isPresented: $showingCreateView)
        }
    }

    private func resetCreateReminderSheetState() {
        showingCreateView = false
        remindersData.pendingNewReminderTitle = nil
    }
}

#Preview {
    CreateReminderButton()
        .environmentObject(RemindersData())
}
