import SwiftUI

struct SearchRemindersButton: View {
    @EnvironmentObject var remindersData: RemindersData
    @ObservedObject var userPreferences = UserPreferences.shared

    var body: some View {
        Button(action: {
            remindersData.showingSearch.toggle()
        }) {
            ToolbarButtonLabel {
                Image(systemName: "magnifyingglass")
            }
        }
        .keyboardShortcut("f", modifiers: .command)
        .modifier(ToolbarButtonModifier())
        .background(
            remindersData.showingSearch
                ? Color.rmbColor(
                    for: .buttonHover,
                    isTransparencyEnabled: userPreferences.isTransparencyEnabled
                )
                : nil
        )
        .cornerRadius(8)
        .help(rmbLocalized(.searchRemindersButtonHelp))
    }
}

#Preview {
    SearchRemindersButton()
        .environmentObject(RemindersData())
}
