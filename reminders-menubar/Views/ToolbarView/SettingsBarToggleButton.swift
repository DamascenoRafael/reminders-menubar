import SwiftUI

struct SettingsBarToggleButton: View {
    @ObservedObject var userPreferences = UserPreferences.shared
    
    var body: some View {
        Button(action: {
            userPreferences.showUncompletedOnly.toggle()
        }) {
            ToolbarButtonLabel {
                Image(systemName: "clock.arrow.trianglehead.counterclockwise.rotate.90")
            }
        }
        .modifier(ToolbarButtonModifier())
        .help(rmbLocalized(.showCompletedRemindersToggleButtonHelp))
    }
}

#Preview {
    SettingsBarToggleButton()
}
