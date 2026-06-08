import SwiftUI

struct OpenSettingButton: View {
    var body: some View {
        Button {
            NSApp.openAppSettings()
        } label: {
            ToolbarButtonLabel {
                Image(rmbSymbol: .gearshape)
            }
        }
        .modifier(ToolbarButtonModifier())
        .help(rmbLocalized(.settingsButtonHelp))
    }
}

#Preview {
    OpenSettingButton()
}
