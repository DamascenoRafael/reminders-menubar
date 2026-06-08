import SwiftUI

struct FilterPanelContentView: View {
    @EnvironmentObject var remindersData: RemindersData

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            upcomingRemindersRow

            MenuSeparator()

            calendarsSection

            if #available(macOS 12, *), !remindersData.availableTags.isEmpty {
                MenuSeparator()
                tagsSection
            }
        }
        .modifier(PanelContainerStyle())
    }

    // MARK: - Upcoming Reminders

    private var upcomingRemindersRow: some View {
        SubmenuParentRow(title: rmbLocalized(.upcomingRemindersButton))
            .modifier(SubmenuHoverBehavior(onEnter: {
                FilterPanelController.shared.showSubmenu(
                    contentView: UpcomingSubmenuContent()
                )
            }))
    }

    // MARK: - Calendars

    private var calendarsSection: some View {
        ForEach(remindersData.availableCalendars, id: \.calendarIdentifier) { calendar in
            let isSelected = remindersData.calendarIdentifiersFilter.contains(calendar.calendarIdentifier)
            MenuRow(
                text: ColoredDotTitle.text(calendar.title, color: Color(calendar.color)),
                isSelected: isSelected
            ) {
                if let index = remindersData.calendarIdentifiersFilter.firstIndex(of: calendar.calendarIdentifier) {
                    remindersData.calendarIdentifiersFilter.remove(at: index)
                } else {
                    remindersData.calendarIdentifiersFilter.append(calendar.calendarIdentifier)
                }
            }
        }
    }

    // MARK: - Tags

    @available(macOS 12, *)
    private var tagsSection: some View {
        ForEach(remindersData.availableTags, id: \.self) { tag in
            let isSelected = remindersData.tagsFilter.contains(tag)
            MenuRow(
                text: ColoredDotTitle.text(tag.name, color: Color.rmbColor(.tagHighlight), prefix: "#"),
                isSelected: isSelected
            ) {
                if let index = remindersData.tagsFilter.firstIndex(of: tag) {
                    remindersData.tagsFilter.remove(at: index)
                } else {
                    remindersData.tagsFilter.append(tag)
                }
            }
        }
    }
}

// MARK: - Upcoming Submenu Content

private struct UpcomingSubmenuContent: View {
    @ObservedObject private var userPreferences = UserPreferences.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(ReminderInterval.allCases, id: \.self) { interval in
                MenuRow(
                    text: Text(interval.filterOption),
                    isSelected: userPreferences.upcomingRemindersInterval == interval
                        && userPreferences.showUpcomingReminders
                ) {
                    userPreferences.showUpcomingReminders = true
                    userPreferences.upcomingRemindersInterval = interval
                }
            }

            MenuSeparator()

            MenuRow(
                text: Text(rmbLocalized(.upcomingRemindersNoneFilterOption)),
                isSelected: !userPreferences.showUpcomingReminders
            ) {
                userPreferences.showUpcomingReminders = false
            }
        }
        .modifier(PanelContainerStyle())
        .modifier(SubmenuHoverBehavior())
    }
}

// MARK: - Menu Row

private struct MenuRow: View {
    let text: Text
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            PanelRow { _ in
                HStack(spacing: 0) {
                    Image(rmbSymbol: .checkmark)
                        .font(.system(size: 11, weight: .semibold))
                        .frame(width: 20, alignment: .center)
                        .opacity(isSelected ? 1 : 0)

                    text
                        .font(.system(size: 13))
                        .lineLimit(1)

                    Spacer()
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Submenu Parent Row

private struct SubmenuParentRow: View {
    let title: String

    var body: some View {
        PanelRow { isHovered in
            HStack(spacing: 0) {
                Text(title)
                    .font(.system(size: 13))
                    .lineLimit(1)
                    .padding(.leading, 8)

                Spacer()

                Image(rmbSymbol: .chevronRight)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(isHovered ? .white.opacity(0.8) : .secondary)
                    .padding(.trailing, 2)
            }
        }
    }
}

// MARK: - Panel Row

private struct PanelRow<Content: View>: View {
    @ViewBuilder var content: (_ isHovered: Bool) -> Content

    @State private var isHovered = false

    var body: some View {
        content(isHovered)
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .contentShape(Rectangle())
            .background(
                isHovered
                    ? RoundedRectangle(cornerRadius: 8).fill(Color.accentColor)
                    : nil
            )
            .foregroundColor(isHovered ? .white : .primary)
            .padding(.horizontal, 5)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

// MARK: - Submenu Hover Behavior

private struct SubmenuHoverBehavior: ViewModifier {
    var onEnter: (() -> Void)?

    func body(content: Content) -> some View {
        content.onHover { hovering in
            if hovering {
                FilterPanelController.shared.cancelSubmenuClose()
                onEnter?()
            } else {
                FilterPanelController.shared.scheduleSubmenuClose()
            }
        }
    }
}

// MARK: - Panel Container Style

private struct PanelContainerStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.vertical, 5)
            .frame(minWidth: 120, maxWidth: 300)
            .fixedSize()
            .modifier(MaterialBackgroundModifier())
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.15), lineWidth: 0.5)
            )
    }
}

private struct MaterialBackgroundModifier: ViewModifier {
    @ObservedObject private var userPreferences = UserPreferences.shared

    func body(content: Content) -> some View {
        if #available(macOS 12, *) {
            content
                .background(
                    Color.rmbColor(.backgroundTheme(isTransparent: userPreferences.isTransparencyEnabled))
                )
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        } else {
            content
                .background(
                    Color.rmbColor(.backgroundTheme(isTransparent: false))
                )
        }
    }
}

// MARK: - Menu Separator

private struct MenuSeparator: View {
    var body: some View {
        Divider()
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
    }
}

#Preview {
    FilterPanelContentView()
        .environmentObject(RemindersData())
}
