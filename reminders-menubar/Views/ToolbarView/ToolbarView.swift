import SwiftUI

struct ToolbarView: View {
    var body: some View {
        HStack(spacing: 4) {
            SettingsBarFilterMenu()
            
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
