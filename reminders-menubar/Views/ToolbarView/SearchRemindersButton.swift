import SwiftUI

struct SearchRemindersButton: View {
    @EnvironmentObject var remindersData: RemindersData

    var body: some View {
        Button(action: {
            remindersData.showingSearch.toggle()
        }) {
            ToolbarButtonLabel {
                Image(systemName: "magnifyingglass")
            }
        }
        .keyboardShortcut("f", modifiers: .command)
        .modifier(ToolbarButtonModifier(isActive: remindersData.showingSearch))
        .help(rmbLocalized(.searchRemindersButtonHelp))
    }
}

#Preview {
    SearchRemindersButton()
        .environmentObject(RemindersData())
}
