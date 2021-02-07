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
                    Text("Reminders Menu Bar")
                        .font(Font.title.weight(.thin))
                    Text("Version \(AppConstants.currentVersion)")
                        .font(Font.callout.weight(.light))
                }
                .padding(.bottom, 8)

                VStack(alignment: .leading, spacing: 14) {
                    Text("""
                    Reminders Menu Bar is an open source software \
                    licensed under the terms of the GNU General Public License v3.0.
                    """)
                    Text("Features and updates available on GitHub")
                }
                .font(.system(size: 11))
                .frame(maxHeight: .infinity)
                
                Button(action: {
                    if let url = URL(string: GithubConstants.pageUrlString) {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    Text("See more on GitHub")
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
            window.title = "About Reminders Menu Bar"
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
