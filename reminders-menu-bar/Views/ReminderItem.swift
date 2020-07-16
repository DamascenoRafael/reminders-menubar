import SwiftUI

struct ReminderItem: View {
    @State private var done = true
    var reminder: String
    
    var body: some View {
        HStack (alignment: .top) {
            Button(action: {
                self.done.toggle()
            }) {
                statusImage
                    .resizable()
                    .frame(width: 18, height: 18)
                    .padding(.top, 1)
                    .foregroundColor(.blue)
            }.buttonStyle(PlainButtonStyle())
            VStack {
                HStack {
                    Text(reminder)
                    Spacer()
                }
                Spacer()
                Divider()
            }
        }
    }
    
    private var statusImage: Image {
        if self.done {
            return Image("circle.filled")
        } else {
            return Image("circle")
        }
    }
}

struct TaskItem_Previews: PreviewProvider {
    static var previews: some View {
        ReminderItem(reminder: "Reminder Sample")
    }
}
