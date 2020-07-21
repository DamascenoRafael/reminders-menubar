import SwiftUI
import EventKit

struct SettingsBarView: View {
    @EnvironmentObject var remindersData: RemindersData
    
    var body: some View {
        HStack {
            Button(action: {
                print("filter button")
            }) {
                MenuButton(label:
                    Image("filter.circle")
                        .resizable()
                        .frame(width: 16, height: 16)
                ) {
                    ForEach(remindersData.calendars, id: \.calendarIdentifier) { calendar in
                        Button(action: {
                            let index = self.remindersData.calendarIdentifiersFilter.firstIndex(of: calendar.calendarIdentifier)
                            if let index = index {
                                self.remindersData.calendarIdentifiersFilter.remove(at: index)
                            } else {
                                self.remindersData.calendarIdentifiersFilter.append(calendar.calendarIdentifier)
                            }
                        }) {
                            HStack {
                                Image("circle.filled")
                                    .resizable()
                                    .frame(width: 6, height: 6)
                                    .foregroundColor(Color(calendar.color))
                                Text(calendar.title)
                                Spacer(minLength: 25)
                                if self.remindersData.calendarIdentifiersFilter.contains(calendar.calendarIdentifier) {
                                    Image("checkmark")
                                        .resizable()
                                        .frame(width: 8, height: 8)
                                }
                            }
                        }
                    }
                }
                .menuButtonStyle(BorderlessButtonMenuButtonStyle())
                .frame(width: 16, height: 16)
            }
            
            Spacer()
            
            Button(action: {
                self.remindersData.showUncompletedOnly.toggle()
            }) {
                Image(self.remindersData.showUncompletedOnly ? "circle" : "dot.filled.circle")
                    .resizable()
                    .frame(width: 16, height: 16)
            }
            
            Spacer()
            
            Button(action: {
                print("gear button")
            }) {
                MenuButton(label:
                    Image("gear")
                        .resizable()
                        .frame(width: 16, height: 16)
                ) {
                    Button(action: {
                        self.remindersData.loadCalendars()
                    }) {
                        Text("Reload data")
                    }
                    
                    VStack {
                        Divider()
                    }
                    
                    Button(action: {
                        NSApplication.shared.terminate(self)
                    }) {
                        Text("Quit")
                    }
                }
                .menuButtonStyle(BorderlessButtonMenuButtonStyle())
                .frame(width: 16, height: 16)
            }
            
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 5)
        .padding(.bottom, 10)
        .padding(.horizontal, 10)
        .background(Color("backgroundTheme"))
    }
}

//struct SettingsBarView_Previews: PreviewProvider {
//    static var previews: some View {
//        SettingsBarView(isFilterEnabled: .constant(true))
//    }
//}
