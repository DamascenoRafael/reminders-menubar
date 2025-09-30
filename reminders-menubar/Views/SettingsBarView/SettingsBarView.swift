import SwiftUI

struct SettingsBarView: View {
    var body: some View {
        HStack {
            SettingsBarFilterMenu()
            
            Spacer()
            
            SettingsBarToggleButton()
            
            Spacer()
            
            SettingsBarSyncIndicator()
            SettingsBarGearMenu()
        }
        .frame(maxWidth: .infinity)
        .padding(10)
    }
}

struct SettingsBarView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ForEach(ColorScheme.allCases, id: \.self) { color in
                SettingsBarView()
                    .environmentObject(RemindersData())
                    .colorScheme(color)
                    .previewDisplayName("\(color) mode")
            }
        }
    }
}
