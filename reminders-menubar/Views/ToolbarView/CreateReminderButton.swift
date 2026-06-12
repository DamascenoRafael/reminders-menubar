import SwiftUI

struct CreateReminderButton: View {
    @EnvironmentObject var remindersData: RemindersData
    @State private var showingCreateView = false
    @State private var pendingCreateTitle = ""

    var body: some View {
        Button {
            remindersData.isOpeningCreateReminderSheet = true
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
        .onReceive(remindersData.createReminderPublisher) { title in
            if showingCreateView {
                pendingCreateTitle += title
            } else {
                pendingCreateTitle = title
                showingCreateView = true
            }
        }
        .sheet(isPresented: $showingCreateView, onDismiss: resetCreateReminderSheetState) {
            ReminderEditView(
                isPresented: $showingCreateView,
                initialTitle: pendingCreateTitle
            )
        }
    }

    private func resetCreateReminderSheetState() {
        showingCreateView = false
        pendingCreateTitle = ""
        remindersData.isOpeningCreateReminderSheet = false
        remindersData.pendingCreateReminderTyping = ""
    }
}

#Preview {
    CreateReminderButton()
        .environmentObject(RemindersData())
}
