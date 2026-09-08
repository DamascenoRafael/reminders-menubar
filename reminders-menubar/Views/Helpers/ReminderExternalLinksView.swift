import SwiftUI

struct ReminderExternalLinksView: View {
    let externalLinks: ReminderExternalLinks
    let isCompact: Bool

    var body: some View {
        if isCompact {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    linkRows
                }
            }
        } else {
            VStack(alignment: .leading, spacing: 6) {
                linkRows
            }
        }
    }

    @ViewBuilder private var linkRows: some View {
        ForEach(externalLinks.links) { externalLink in
            ExternalLinkRow(
                icon: icon(for: externalLink.source),
                displayText: displayText(for: externalLink),
                url: externalLink.url,
                isCompact: isCompact
            )
        }
    }

    private func icon(for source: ReminderExternalLinks.Source) -> RmbSymbol {
        switch source {
        case .attached:
            return .safari
        case .mail:
            return .envelope
        case .text:
            return .link
        }
    }

    private func displayText(for link: ReminderExternalLinks.Link) -> String? {
        if link.source == .mail {
            return isCompact ? nil : "Mail"
        }
        return isCompact ? link.url.displayedUrl : link.url.absoluteString
    }
}

private struct ExternalLinkRow: View {
    let icon: RmbSymbol
    let displayText: String?
    let url: URL
    let isCompact: Bool

    var body: some View {
        HStack(spacing: 4) {
            Link(destination: url) {
                Image(rmbSymbol: icon)

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
    @State private var copiedDismissWork: DispatchWorkItem?

    var body: some View {
        Button {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(url.absoluteString, forType: .string)
            isCopied = true
            copiedDismissWork?.cancel()
            let work = DispatchWorkItem { isCopied = false }
            copiedDismissWork = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: work)
        } label: {
            Image(rmbSymbol: isCopied ? .checkmark : .docOnDoc)
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
        externalLinks: ReminderExternalLinks(
            links: [
                .init(url: URL(string: "https://www.github.com")!, source: .attached),
                .init(url: URL(string: "message://test")!, source: .mail),
                .init(url: URL(string: "https://swift.org")!, source: .text),
                .init(url: URL(string: "https://developer.apple.com")!, source: .text),
                .init(url: URL(string: "https://github.com/apple/swift")!, source: .text)
            ]
        ),
        isCompact: true
    )
    .padding()
    .frame(width: 260)
}

#Preview("Expanded") {
    ReminderExternalLinksView(
        externalLinks: ReminderExternalLinks(
            links: [
                .init(url: URL(string: "https://www.github.com/DamascenoRafael/reminders-menubar")!, source: .attached),
                .init(url: URL(string: "message://test")!, source: .mail),
                .init(url: URL(string: "https://swift.org")!, source: .text),
                .init(url: URL(string: "mailto:test@example.com")!, source: .text)
            ]
        ),
        isCompact: false
    )
    .padding()
    .frame(width: 260)
}
