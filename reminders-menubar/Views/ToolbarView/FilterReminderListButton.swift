import SwiftUI

struct FilterReminderListButton: View {
    @EnvironmentObject var remindersData: RemindersData

    @State private var menuAnchorView: NSView?

    var body: some View {
        Button {
            showFilterMenu()
        } label: {
            ToolbarButtonLabel {
                Image(systemName: "line.horizontal.3.decrease.circle")
            }
        }
        .modifier(ToolbarButtonModifier())
        .background(MenuAnchorView(nsView: $menuAnchorView))
        .help(rmbLocalized(.remindersFilterSelectionHelp))
    }

    private func showFilterMenu() {
        let menu = NSMenu()

        let upcomingItem = CallbackMenuItem(
            title: rmbLocalized(.upcomingRemindersButton)
        ) {
            NSApp.openAppSettings(tab: .reminders)
        }
        menu.addItem(upcomingItem)

        menu.addItem(.separator())

        for calendar in remindersData.calendars {
            let calendarIdentifier = calendar.calendarIdentifier
            let isSelected = remindersData.calendarIdentifiersFilter.contains(calendarIdentifier)

            let item = CallbackMenuItem(title: calendar.title) { [weak remindersData] in
                guard let remindersData else { return }
                if let index = remindersData.calendarIdentifiersFilter.firstIndex(of: calendarIdentifier) {
                    remindersData.calendarIdentifiersFilter.remove(at: index)
                } else {
                    remindersData.calendarIdentifiersFilter.append(calendarIdentifier)
                }
            }
            item.state = isSelected ? .on : .off

            item.attributedTitle = ColoredDotTitle.attributedString(calendar.title, color: calendar.color)

            menu.addItem(item)
        }

        if let anchorView = menuAnchorView {
            let position = NSPoint(x: 0, y: -4)
            menu.popUp(positioning: nil, at: position, in: anchorView)
        }
    }
}

private struct MenuAnchorView: NSViewRepresentable {
    @Binding var nsView: NSView?

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            nsView = view
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

private final class CallbackMenuItem: NSMenuItem {
    private let callback: () -> Void

    init(title: String, callback: @escaping () -> Void) {
        self.callback = callback
        super.init(title: title, action: #selector(performAction), keyEquivalent: "")
        self.target = self
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func performAction() {
        callback()
    }
}

#Preview {
    FilterReminderListButton()
        .environmentObject(RemindersData())
}
