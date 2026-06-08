import SwiftUI

struct NoFilterSelectedView: View {
    var body: some View {
        VStack(spacing: 4) {
            Image(rmbSymbol: .filterCircle)
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
