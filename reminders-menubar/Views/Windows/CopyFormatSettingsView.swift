import AppKit
import SwiftUI

struct CopyFormatSettingsView: View {
    @ObservedObject var userPreferences = UserPreferences.shared
    @State private var templateText: String = UserPreferences.shared.copyTemplate

    private let availableVariables = [
        "{title}", "{notes}", "{date}", "{priority}", "{list}", "{url}"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            templateSection()
            variablesSection()
            trimSection()
            previewSection()
        }
        .padding(24)
        .frame(width: 420, height: 340)
    }

    @ViewBuilder
    private func templateSection() -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(rmbLocalized(.copyFormatTemplateLabel))
                .font(.headline)

            TextField(
                rmbLocalized(.copyFormatTemplatePlaceholder),
                text: $templateText
            )
            .textFieldStyle(.roundedBorder)
            .font(.system(.body, design: .monospaced))
            .onChange(of: templateText) { newValue in
                userPreferences.copyTemplate = newValue
            }

            Text(rmbLocalized(.copyFormatTemplateHint))
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    @ViewBuilder
    private func variablesSection() -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(rmbLocalized(.copyFormatAvailableVariables))
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack(spacing: 6) {
                ForEach(availableVariables, id: \.self) { variable in
                    Text(variable)
                        .font(.system(.caption, design: .monospaced))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.secondary.opacity(0.15))
                        .cornerRadius(4)
                }
            }
        }
    }

    @ViewBuilder
    private func trimSection() -> some View {
        Toggle(rmbLocalized(.copyFormatTrimOption), isOn: $userPreferences.copyTrimEnabled)
    }

    @ViewBuilder
    private func previewSection() -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(rmbLocalized(.copyFormatPreviewLabel))
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text(previewText)
                .font(.system(.body, design: .monospaced))
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.secondary.opacity(0.08))
                .cornerRadius(6)
        }
    }

    private var previewText: String {
        let text = ReminderCopyService.previewText(
            template: templateText,
            trim: userPreferences.copyTrimEnabled
        )
        return text.isEmpty ? " " : text
    }

    // Keep the window controller alive for the lifetime of the app so the window doesn't get
    // deallocated immediately after `showWindow()` returns.
    private static var windowController: NSWindowController?

    @MainActor
    static func showWindow() {
        if let existing = windowController, let window = existing.window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let viewController = NSHostingController(rootView: CopyFormatSettingsView())
        let windowController = NSWindowController(window: NSWindow(contentViewController: viewController))

        if let window = windowController.window {
            window.title = rmbLocalized(.copyFormatSettingsWindowTitle)
            window.titlebarAppearsTransparent = true
            window.animationBehavior = .alertPanel
            window.styleMask = [.titled, .closable]
            window.isReleasedWhenClosed = false
            window.center()
        }

        self.windowController = windowController
        windowController.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

#Preview {
    CopyFormatSettingsView()
}
