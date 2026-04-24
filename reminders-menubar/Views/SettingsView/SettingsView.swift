import SwiftUI

enum SettingsTab: Hashable {
    case general
    case menuBar
    case reminders
    case copy
    case keyboard
    case about
}

struct SettingsView: View {
    @ObservedObject private var coordinator = SettingsCoordinator.shared

    var body: some View {
        TabView(selection: $coordinator.selectedTab) {
            GeneralSettingsTab()
                .tabItem {
                    Label(rmbLocalized(.generalSettingsTab), systemImage: "gearshape")
                }
                .tag(SettingsTab.general)

            MenuBarSettingsTab()
                .tabItem {
                    Label(rmbLocalized(.menuBarSettingsTab), systemImage: "menubar.rectangle")
                }
                .tag(SettingsTab.menuBar)

            ReminderSettingsTab()
                .tabItem {
                    Label(rmbLocalized(.remindersSettingsTab), systemImage: "list.bullet")
                }
                .tag(SettingsTab.reminders)

            CopySettingsTab()
                .tabItem {
                    Label(rmbLocalized(.copySettingsTab), systemImage: "doc.on.doc")
                }
                .tag(SettingsTab.copy)

            KeyboardSettingsTab()
                .tabItem {
                    Label(rmbLocalized(.keyboardSettingsTab), systemImage: "keyboard")
                }
                .tag(SettingsTab.keyboard)

            AboutSettingsTab()
                .tabItem {
                    Label(rmbLocalized(.aboutSettingsTab), systemImage: "info.circle")
                }
                .tag(SettingsTab.about)
        }
        .frame(width: 620)
    }
}

#Preview {
    SettingsView()
}
