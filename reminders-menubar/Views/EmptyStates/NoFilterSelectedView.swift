import SwiftUI

struct NoFilterSelectedView: View {
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: "line.horizontal.3.decrease.circle")
                .font(.title)

            Text(rmbLocalized(.emptyListNoRemindersFilterTitle))
                .font(.headline)
                .multilineTextAlignment(.center)
            
            Text(rmbLocalized(.emptyListNoRemindersFilterMessage))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 36)
    }
}

#Preview {
    NoFilterSelectedView()
}
