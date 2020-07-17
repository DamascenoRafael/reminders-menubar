import SwiftUI
import EventKit

struct ReminderItemView: View {
    @State var reminder: EKReminder
    
    var body: some View {
        HStack (alignment: .top) {
            Button(action: {
                self.reminder.isCompleted.toggle()
            }) {
                Image(self.reminder.isCompleted ? "circle.filled" : "circle")
                    .resizable()
                    .frame(width: 18, height: 18)
                    .padding(.top, 1)
                    .foregroundColor(Color(reminder.calendar.color))
            }.buttonStyle(PlainButtonStyle())
            VStack {
                HStack {
                    Text(reminder.title)
                    Spacer()
                }
                Spacer()
                Divider()
            }
        }
    }
}

//struct ReminderItemView_Previews: PreviewProvider {
//    static var previews: some View {
////        ReminderItemView()
//    }
//}
