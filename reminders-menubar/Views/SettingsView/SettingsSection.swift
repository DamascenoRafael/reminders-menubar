import SwiftUI

struct SettingsSection<Content: View>: View {
    let label: String
    let content: Content

    init(_ label: String = " ", @ViewBuilder content: () -> Content) {
        self.label = label
        self.content = content()
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .frame(width: 160, alignment: .trailing)
                .font(.body)

            VStack(alignment: .leading, spacing: 8) {
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
