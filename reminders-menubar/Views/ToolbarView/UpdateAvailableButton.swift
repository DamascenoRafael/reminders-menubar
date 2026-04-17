import SwiftUI

struct UpdateAvailableButton: View {
    @ObservedObject var updateController = UpdateController.shared

    var body: some View {
        if updateController.isOutdated {
            Button(action: {
                updateController.showUpdate()
            }) {
                ToolbarButtonLabel {
                    Image(systemName: "arrow.down.circle")
                }
            }
            .modifier(ToolbarButtonModifier())
            .help(rmbLocalized(.updateAvailableNoticeButton))
        }
    }
}

#Preview {
    UpdateAvailableButton()
}
