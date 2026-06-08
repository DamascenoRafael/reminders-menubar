import SwiftUI

struct FilterReminderListButton: View {
    @EnvironmentObject var remindersData: RemindersData
    @ObservedObject private var panelController = FilterPanelController.shared

    @State private var anchorView: NSView?

    var body: some View {
        Button {
            showFilterPanel()
        } label: {
            ToolbarButtonLabel {
                Image(rmbSymbol: .filterCircle)
            }
        }
        .modifier(ToolbarButtonModifier(isActive: panelController.isVisible))
        .background(PanelAnchorView(nsView: $anchorView))
        .help(rmbLocalized(.remindersFilterSelectionHelp))
    }

    private func showFilterPanel() {
        guard let anchorView else { return }
        let contentView = FilterPanelContentView()
            .environmentObject(remindersData)
        panelController.toggle(relativeTo: anchorView, contentView: contentView)
    }
}

private struct PanelAnchorView: NSViewRepresentable {
    @Binding var nsView: NSView?

    func makeNSView(context: Context) -> NSView {
        NSView()
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        if self.nsView !== nsView {
            DispatchQueue.main.async {
                self.nsView = nsView
            }
        }
    }
}

#Preview {
    FilterReminderListButton()
        .environmentObject(RemindersData())
}
