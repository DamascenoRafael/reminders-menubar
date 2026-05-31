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

        for calendar in remindersData.availableCalendars {
            let calendarIdentifier = calendar.calendarIdentifier
            let isSelected = remindersData.calendarIdentifiersFilter.contains(calendarIdentifier)

            let item = makeToggleItem(
                title: calendar.title,
                attributedTitle: ColoredDotTitle.attributedString(calendar.title, color: calendar.color),
                isSelected: isSelected
            ) { [weak remindersData] in
                guard let remindersData else { return }
                if let index = remindersData.calendarIdentifiersFilter.firstIndex(of: calendarIdentifier) {
                    remindersData.calendarIdentifiersFilter.remove(at: index)
                } else {
                    remindersData.calendarIdentifiersFilter.append(calendarIdentifier)
                }
            }
            menu.addItem(item)
        }

        if #available(macOS 12, *), !remindersData.availableTags.isEmpty {
            menu.addItem(.separator())

            for tag in remindersData.availableTags {
                let isSelected = remindersData.tagsFilter.contains(tag)

                let item = makeToggleItem(
                    title: tag.name,
                    attributedTitle: ColoredDotTitle.attributedString(
                        tag.name,
                        color: RmbColor.tagHighlight.nsColor,
                        prefix: "#"
                    ),
                    isSelected: isSelected
                ) { [weak remindersData] in
                    guard let remindersData else { return }
                    if let index = remindersData.tagsFilter.firstIndex(of: tag) {
                        remindersData.tagsFilter.remove(at: index)
                    } else {
                        remindersData.tagsFilter.append(tag)
                    }
                }
                menu.addItem(item)
            }
        }

        if let anchorView = menuAnchorView {
            let position = NSPoint(x: 0, y: -4)
            menu.popUp(positioning: nil, at: position, in: anchorView)
        }
    }

    private func makeToggleItem(
        title: String,
        attributedTitle: NSAttributedString,
        isSelected: Bool,
        callback: @escaping () -> Void
    ) -> CallbackMenuItem {
        let item = CallbackMenuItem(title: title, callback: callback)
        item.state = isSelected ? .on : .off
        item.attributedTitle = attributedTitle
        return item
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
