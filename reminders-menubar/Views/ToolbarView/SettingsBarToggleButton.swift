import SwiftUI

struct SettingsBarToggleButton: View {
    @ObservedObject var userPreferences = UserPreferences.shared
    
    var body: some View {
        Button(action: {
            userPreferences.showUncompletedOnly.toggle()
        }) {
            Image(systemName: userPreferences.showUncompletedOnly ? "circle" : "largecircle.fill.circle")
        }
        .modifier(ToolbarButtonModifier())
        .help(rmbLocalized(.showCompletedRemindersToggleButtonHelp))
    }
}

#Preview {
    SettingsBarToggleButton()
}
