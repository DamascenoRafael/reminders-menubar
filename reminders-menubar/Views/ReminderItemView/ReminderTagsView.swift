import SwiftUI

struct ReminderTagsView: View {
    let tags: [String]

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "number")
                .font(.system(size: 9))
                .foregroundColor(.secondary)

            ForEach(tags, id: \.self) { tag in
                Text(tag)
                    .modifier(TagPillModifier(size: .compact))
            }

            Spacer()
        }
        .font(.footnote)
    }
}

#Preview {
    ReminderTagsView(tags: ["sample", "review"])
}
