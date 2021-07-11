import SwiftUI

struct AboutView: View {
    
    var body: some View {
        HStack(alignment: .center) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 96, height: 96)
                .shadow(radius: 5)
                .padding(16)
                .padding(.horizontal, 6)
                .padding(.bottom, 22)
            
            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading) {
                    Text(AppConstants.appName)
                        .font(Font.title.weight(.thin))
                    Text(rmbLocalized(.appVersionDescription, arguments: AppConstants.currentVersion))
                        .font(Font.callout.weight(.light))
                }
                .padding(.bottom, 4)

                VStack(alignment: .leading, spacing: 14) {
                    Text(rmbLocalized(.remindersMenuBarAppAboutDescription,
                                      arguments: AppConstants.appName,
                                      "GNU General Public License v3.0"))
                    Text(rmbLocalized(.remindersMenuBarGitHubAboutDescription))
                }
                .font(.system(size: 11))
                .frame(maxHeight: .infinity)
                
                Button(action: {
                    if let url = URL(string: GithubConstants.repositoryPage) {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    Text(rmbLocalized(.seeMoreOnGitHubButton))
                }
            }
        }
        .padding(.top, 10)
        .padding(.bottom, 24)
        .padding(.horizontal, 16)
        .frame(width: 525, height: 200)
    }
    
    static func showWindow() {
        let viewController = NSHostingController(rootView: AboutView())
        let windowController = NSWindowController(window: NSWindow(contentViewController: viewController))
        
        if let window = windowController.window {
            window.title = rmbLocalized(.aboutRemindersMenuBarWindowTitle, arguments: AppConstants.appName)
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.animationBehavior = .alertPanel
            window.styleMask = [.titled, .closable]
        }
        
        windowController.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
    }
}
