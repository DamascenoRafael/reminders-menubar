import SwiftUI

struct AboutSettingsTab: View {
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            Image(nsImage: NSApp.applicationIconImage)
                .frame(width: 140, height: 140)
                .padding(24)

            VStack(alignment: .leading, spacing: 0) {
                Text(AppConstants.appName)
                    .font(.system(size: 28))

                Text(rmbLocalized(.appVersionDescription, arguments: AppConstants.currentVersion))
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .padding(.top, 12)

                VStack(alignment: .leading, spacing: 10) {
                    Text(rmbLocalized(
                        .remindersMenuBarAppAboutDescription,
                        arguments: AppConstants.appName,
                        "GNU General Public License v3.0"
                    ))
                    Text(rmbLocalized(.remindersMenuBarGitHubAboutDescription))
                }
                .font(.system(size: 11))
                .padding(.trailing, 24)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 28)

                Button(action: {
                    if let url = URL(string: GithubConstants.repositoryPage) {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    Text(rmbLocalized(.seeMoreOnGitHubButton))
                }
                .padding(.top, 12)
            }
            .padding(.top, 32)
            .padding(.bottom, 20)
            .padding(.trailing, 24)
        }
    }
}

#Preview {
    AboutSettingsTab()
}
