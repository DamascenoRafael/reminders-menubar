import SwiftUI

struct ReminderTagsView: View {
    let tagNames: [String]

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "number")
                .font(.system(size: 9))
                .foregroundColor(.secondary)

            ForEach(tagNames, id: \.self) { tag in
                Text(tag)
                    .modifier(TagPillModifier(size: .compact))
            }

            Spacer()
        }
        .font(.footnote)
    }
}

#Preview {
    ReminderTagsView(tagNames: ["sample", "review"])
}
