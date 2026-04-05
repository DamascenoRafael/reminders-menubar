import SwiftUI

struct ShowMoreRemindersButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(rmbLocalized(.showMoreRemindersButton))
                .font(.callout)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .buttonStyle(.borderless)
        .padding(.vertical, 4)
    }
}
