import EventKit

struct ReminderExternalLinks {
    enum Source {
        case attached
        case mail
        case text
    }

    struct Link: Identifiable {
        let url: URL
        let source: Source

        var id: String { url.absoluteString }
    }

    let links: [Link]

    var isEmpty: Bool {
        links.isEmpty
    }

    init(links: [Link]) {
        self.links = links
    }

    init(reminder: EKReminder) {
        self.init(reminder: reminder, title: reminder.title, notes: reminder.notes)
    }

    init(draft: RmbReminder) {
        self.init(reminder: nil, title: draft.title, notes: draft.notes)
    }

    init(reminder: EKReminder, draft: RmbReminder) {
        self.init(reminder: reminder, title: draft.title, notes: draft.notes)
    }

    private init(reminder: EKReminder?, title: String, notes: String?) {
        var links = [Link]()
        var seenUrls = Set<String>()

        func append(_ url: URL?, source: Source) {
            guard let url, seenUrls.insert(url.absoluteString).inserted else {
                return
            }
            links.append(Link(url: url, source: source))
        }

        append(reminder?.attachedUrl, source: .attached)
        append(reminder?.mailUrl, source: .mail)
        title.detectedUrls().forEach { append($0, source: .text) }
        notes?.detectedUrls().forEach { append($0, source: .text) }

        self.links = links
    }
}
