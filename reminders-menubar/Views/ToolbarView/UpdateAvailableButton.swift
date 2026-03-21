import SwiftUI

struct UpdateAvailableButton: View {
    @ObservedObject var appUpdateCheckHelper = AppUpdateCheckHelper.shared
    
    var body: some View {
        if appUpdateCheckHelper.isOutdated {
            Button(action: {
                if let url = URL(string: GithubConstants.latestReleasePage) {
                    NSWorkspace.shared.open(url)
                }
            }) {
                Image(systemName: "arrow.down.circle")
            }
            .modifier(ToolbarButtonModifier())
            .help(rmbLocalized(.updateAvailableNoticeButton))
        }
    }
}

#Preview {
    UpdateAvailableButton()
}
