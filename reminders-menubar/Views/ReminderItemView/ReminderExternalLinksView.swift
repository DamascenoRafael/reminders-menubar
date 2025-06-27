import SwiftUI

struct ReminderExternalLinksView: View {
    var attachedUrl: URL?
    var mailUrl: URL?

    var body: some View {
        HStack {
            if let attachedUrl {
                Link(destination: attachedUrl) {
                    Image(systemName: "safari")
                    Text(attachedUrl.displayedUrl)
                }
                .modifier(ReminderExternalLinkStyle())
            }

            if let mailUrl {
                Link(destination: mailUrl) {
                    Image(systemName: "envelope")
                }
                .modifier(ReminderExternalLinkStyle())
            }

            Spacer()
        }
    }

    struct ReminderExternalLinkStyle: ViewModifier {
        func body(content: Content) -> some View {
            return content
                .foregroundColor(.primary)
                .frame(height: 25)
                .padding(.horizontal, 8)
                .background(Color.secondary.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

#Preview {
    ReminderExternalLinksView(attachedUrl: URL(string: "https://www.github.com"), mailUrl: nil)
}
