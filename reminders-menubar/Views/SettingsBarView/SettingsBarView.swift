import SwiftUI

struct SettingsBarView: View {
    var body: some View {
        HStack(spacing: 4) {
            SettingsBarFilterMenu()
            
            SettingsBarToggleButton()
            
            SettingsBarGearMenu()
        }
        .padding(.vertical, 10)
        .padding(.trailing, 10)
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
