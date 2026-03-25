import SwiftUI

struct CreateReminderButton: View {
    @State private var isHovered = false
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
        .buttonStyle(.borderless)
        .foregroundColor(.primary)
        .background(Color.accentColor.opacity(isHovered ? 1 : 0.5))
        .cornerRadius(8)
        .onHover { hovering in
            isHovered = hovering
        }
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
