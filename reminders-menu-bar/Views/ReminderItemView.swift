import SwiftUI
import EventKit

struct ReminderItemView: View {
    @EnvironmentObject var remindersData: RemindersData
    
    @State var reminder: EKReminder
    var reload: () -> Void
    
    var body: some View {
        HStack (alignment: .top) {
            Button(action: {
                self.reminder.isCompleted.toggle()
                RemindersService.instance.save(reminder: self.reminder)
                self.reload()
            }) {
                Image(self.reminder.isCompleted ? "dot.filled.circle" : "circle")
                    .resizable()
                    .frame(width: 18, height: 18)
                    .padding(.top, 1)
                    .foregroundColor(Color(reminder.calendar.color))
            }.buttonStyle(PlainButtonStyle())
            VStack {
                HStack {
                    Text(reminder.title)
                    Spacer()
                    MenuButton(label:
                        Image("ellipsis")
                            .resizable()
                            .aspectRatio(1, contentMode: .fit)
                            .foregroundColor(.gray)
                    ) {
                        MenuButton(label:
                            HStack {
                                Image("folder")
                                    .resizable()
                                    .aspectRatio(1, contentMode: .fit)
                                Spacer()
                                    .frame(width: 12)
                                Text("Move to ...")
                            }
                        ) {
                            ForEach(remindersData.calendars.filter({ $0.calendarIdentifier != self.reminder.calendar.calendarIdentifier }), id: \.calendarIdentifier) { calendar in
                                Button(action: {
                                    self.reminder.calendar = calendar
                                    RemindersService.instance.save(reminder: self.reminder)
                                    self.reload()
                                }) {
                                    HStack {
                                        Image("circle.filled")
                                            .resizable()
                                            .frame(width: 6, height: 6)
                                            .foregroundColor(Color(calendar.color))
                                        Text(calendar.title)
                                    }
                                }
                            }
                        }
                        
                        VStack {
                            Divider()
                        }
                        
                        Button(action: {
                            RemindersService.instance.remove(reminder: self.reminder)
                            self.reload()
                        }) {
                            HStack {
                                Image("minus.circle")
                                    .resizable()
                                    .aspectRatio(1, contentMode: .fit)
                                    .foregroundColor(.red)
                                Spacer()
                                    .frame(width: 12)
                                Text("Remove")
                            }
                        }
                    }
                    .menuButtonStyle(BorderlessButtonMenuButtonStyle())
                    .frame(width: 16, height: 16)
                    .padding(.top, 1)
                    .padding(.trailing, 10)
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
