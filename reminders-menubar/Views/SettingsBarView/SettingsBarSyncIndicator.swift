import SwiftUI

struct SettingsBarSyncIndicator: View {
    @ObservedObject private var manualSyncService = ManualSyncService.shared
    @ObservedObject private var userPreferences = UserPreferences.shared

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        HStack(spacing: 6) {
            Button {
                manualSyncService.trigger(reason: "Toolbar Icon")
            } label: {
                Image(systemName: manualSyncService.isSyncing ? "arrow.triangle.2.circlepath.circle.fill" : "arrow.triangle.2.circlepath.circle")
                    .foregroundColor(manualSyncService.isSyncing ? .accentColor : .secondary)
            }
            .buttonStyle(.plain)
            .disabled(manualSyncService.isSyncing)
            .help(manualSyncService.isSyncing ? "Syncing with Bob…" : "Sync with Bob now")

            if let date = userPreferences.lastSyncDate {
                Text(Self.formatter.string(from: date))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .help("Last sync with Bob")
            } else {
                Text("No Bob sync")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .help("Bob sync has not run yet")
            }
        }
    }
}
