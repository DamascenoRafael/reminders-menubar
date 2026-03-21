import SwiftUI

struct ToolbarView: View {
    var body: some View {
        HStack(spacing: 4) {
            SettingsBarFilterMenu()
            
            SettingsBarToggleButton()

            UpdateAvailableButton()

            OpenSettingButton()
        }
        .padding(.top, 10)
        .padding(.trailing, 10)
        .padding(.leading, 14)
        .padding(.bottom, 6)
    }
}

#Preview {
    ToolbarView()
        .environmentObject(RemindersData())
}
