import SwiftUI

struct ReminderLoadingView: View {
    let message: String

    var body: some View {
        HStack(alignment: .center) {
            ProgressView()
                .controlSize(.small)
            Text(message)
        }
        .font(.callout)
    }
}
