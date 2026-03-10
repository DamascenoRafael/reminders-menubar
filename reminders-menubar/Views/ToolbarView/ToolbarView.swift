import SwiftUI

struct ToolbarView: View {
    var body: some View {
        HStack(spacing: 4) {
            SettingsBarFilterMenu()
            ReminderSortMenu()
            SettingsBarToggleButton()

            UpdateAvailableButton()

            OpenSettingButton()
        }
        .padding(.vertical, 10)
        .padding(.trailing, 10)
    }
}

#Preview {
    ToolbarView()
        .environmentObject(RemindersData())
}

struct ReminderSortMenu: View {
    @ObservedObject var userPreferences = UserPreferences.shared

    var body: some View {
        Menu {
            ForEach(ReminderSortOption.allCases, id: \.self) { sortOption in
                Button(action: {
                    userPreferences.reminderSortOption = sortOption
                }) {
                    SelectableView(
                        title: sortOption.title,
                        isSelected: sortOption == userPreferences.reminderSortOption
                    )
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
        }
        .frame(width: 28)
        .modifier(ToolbarButtonModifier())
        .help(rmbLocalized(.reminderSortButtonHelp))
    }
}
