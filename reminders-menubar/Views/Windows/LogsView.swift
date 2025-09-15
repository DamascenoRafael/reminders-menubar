import SwiftUI

struct LogsView: View {
    @ObservedObject var logger = LogService.shared
    @State private var selectedCategory: LogCategory? = nil

    private var filteredEntries: [LogEntry] {
        let base = logger.entries.sorted { $0.timestamp > $1.timestamp }
        guard let cat = selectedCategory else { return base }
        return base.filter { $0.category == cat }
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                Text("Logs").font(.headline)
                Picker("Category", selection: $selectedCategory) {
                    Text("All").tag(LogCategory?.none)
                    ForEach(LogCategory.allCases, id: \.rawValue) { cat in
                        Text(cat.rawValue).tag(LogCategory?.some(cat))
                    }
                }
                .pickerStyle(.segmented)

                Spacer()

                Button("Copy All") {
                    let text = logger.entries.map { Self.format($0) }.joined(separator: "\n")
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(text, forType: .string)
                }
                Button("Clear") { logger.clear() }
            }
            .padding([.top, .horizontal], 8)

            Divider()

            List(filteredEntries) { entry in
                HStack(alignment: .top, spacing: 8) {
                    Text(Self.shortDate(entry.timestamp)).monospacedDigit().foregroundColor(.secondary)
                    Text("[\(entry.level.rawValue)]").foregroundColor(Self.color(for: entry.level)).font(.system(size: 11)).monospaced()
                    Text("[\(entry.category.rawValue)]").foregroundColor(.secondary)
                    Text(entry.message)
                    Spacer()
                }
                .textSelection(.enabled)
            }
        }
        .frame(width: 780, height: 420)
    }

    static func shortDate(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "HH:mm:ss"
        return f.string(from: d)
    }

    static func format(_ e: LogEntry) -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return "\(f.string(from: e.timestamp)) [\(e.level.rawValue)] [\(e.category.rawValue)] \(e.message)"
    }

    static func color(for level: LogLevel) -> Color {
        switch level {
        case .debug: return .gray
        case .info: return .blue
        case .warn: return .orange
        case .error: return .red
        }
    }
}

extension LogsView {
    static func showWindow() {
        let viewController = NSHostingController(rootView: LogsView())
        let windowController = NSWindowController(window: NSWindow(contentViewController: viewController))
        if let window = windowController.window {
            window.title = "Logs"
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.styleMask = [.titled, .closable, .resizable]
        }
        windowController.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
