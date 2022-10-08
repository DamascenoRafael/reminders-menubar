import SwiftUI

struct SettingsBarToggleButton: View {
    @ObservedObject var userPreferences = UserPreferences.instance
    
    @State var toggleIsHovered = false
    
    var body: some View {
        Button(action: {
            userPreferences.showUncompletedOnly.toggle()
        }) {
            Image(systemName: userPreferences.showUncompletedOnly ? "circle" : "largecircle.fill.circle")
                .padding(4)
                .padding(.horizontal, 4)
        }
        .buttonStyle(BorderlessButtonStyle())
        .background(toggleIsHovered ? Color("buttonHover") : nil)
        .cornerRadius(4)
        .onHover { isHovered in
            toggleIsHovered = isHovered
        }
        .help(rmbLocalized(.showCompletedRemindersToggleButtonHelp))
    }
}

struct SettingsBarToggleButton_Previews: PreviewProvider {
    static var previews: some View {
        SettingsBarToggleButton()
    }
}
