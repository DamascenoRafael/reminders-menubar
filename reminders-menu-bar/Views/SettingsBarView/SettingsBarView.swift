import SwiftUI

struct SettingsBarView: View {
    var body: some View {
        HStack {
            SettingsBarFilterMenu()
            
            Spacer()
            
            SettingsBarToggleButton()
            
            Spacer()
            
            SettingsBarGearMenu()
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 12)
        .padding(.bottom, 10)
        .padding(.horizontal, 10)
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
