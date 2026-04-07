import SwiftUI

struct ReminderExternalLinksView: View {
    var attachedUrl: URL?
    var mailUrl: URL?
    var isCompact: Bool

    var body: some View {
        if isCompact {
            HStack {
                linkRows
                Spacer()
            }
        } else {
            VStack(alignment: .leading, spacing: 6) {
                linkRows
            }
        }
    }

    @ViewBuilder private var linkRows: some View {
        if let attachedUrl {
            ExternalLinkRow(
                icon: "safari",
                displayText: isCompact ? attachedUrl.displayedUrl : attachedUrl.absoluteString,
                url: attachedUrl,
                isCompact: isCompact
            )
        }

        if let mailUrl {
            ExternalLinkRow(
                icon: "envelope",
                displayText: isCompact ? nil : "Mail",
                url: mailUrl,
                isCompact: isCompact
            )
        }
    }
}

private struct ExternalLinkRow: View {
    let icon: String
    let displayText: String?
    let url: URL
    let isCompact: Bool

    var body: some View {
        HStack(spacing: 4) {
            Link(destination: url) {
                Image(systemName: icon)

                if let displayText {
                    Text(displayText)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
            .modifier(ExternalLinkStyle())

            if !isCompact {
                CopyLinkButton(url: url)
            }
        }
    }
}

private struct CopyLinkButton: View {
    let url: URL

    @State private var isCopied = false

    var body: some View {
        Button {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(url.absoluteString, forType: .string)
            isCopied = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                isCopied = false
            }
        } label: {
            Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                .font(.system(size: 10))
                .frame(width: 10)
                .foregroundColor(.secondary)
        }
        .buttonStyle(.borderless)
        .modifier(ExternalLinkStyle())
    }
}

private struct ExternalLinkStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.footnote)
            .foregroundColor(.secondary)
            .frame(height: 20)
            .padding(.horizontal, 8)
            .background(Color.secondary.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview("Compact") {
    ReminderExternalLinksView(
        attachedUrl: URL(string: "https://www.github.com"),
        mailUrl: URL(string: "message://test"),
        isCompact: true
    )
    .padding()
    .frame(width: 260)
}

#Preview("Expanded") {
    ReminderExternalLinksView(
        attachedUrl: URL(string: "https://www.github.com/DamascenoRafael/reminders-menubar"),
        mailUrl: URL(string: "message://test"),
        isCompact: false
    )
    .padding()
    .frame(width: 260)
}
