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
        .modifier(ToolbarButtonModifier())
        .background(
            remindersData.showingSearch
                ? Color.rmbColor(.buttonHover)
                : nil
        )
        .cornerRadius(8)
        .help(rmbLocalized(.searchRemindersButtonHelp))
    }
}

#Preview {
    SearchRemindersButton()
        .environmentObject(RemindersData())
}
