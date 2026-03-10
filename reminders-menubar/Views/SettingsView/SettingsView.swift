import SwiftUI

enum SettingsTab: Hashable {
    case general
    case reminders
    case copy
    case keyboard
    case about
}

struct SettingsView: View {
    @State private var selectedTab: SettingsTab = .general

    static var initialTab: SettingsTab = .general

    var body: some View {
        TabView(selection: $selectedTab) {
            GeneralSettingsTab()
                .tabItem {
                    Label(rmbLocalized(.generalSettingsTab), systemImage: "gearshape")
                }
                .tag(SettingsTab.general)

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
        .onAppear {
            selectedTab = Self.initialTab
            Self.initialTab = .general
        }
        .frame(width: 620)
    }
}

#Preview {
    SettingsView()
}
