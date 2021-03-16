import SwiftUI

struct UpcomingRemindersTitle: View {
    @EnvironmentObject var remindersData: RemindersData
    
    @State var intervalButtonIsHovered = false
    
    var body: some View {
        HStack(alignment: .center) {
            Text("Upcoming reminders")
                .font(.headline)
                .foregroundColor(.red)
                .padding(.bottom, 5)
            
            Spacer()
            
            Menu {
                ForEach(ReminderInterval.allCases, id: \.rawValue) { interval in
                    Button(action: { remindersData.upcomingRemindersInterval = interval }) {
                        let isSelected = interval == remindersData.upcomingRemindersInterval
                        SelectableView(title: interval.rawValue, isSelected: isSelected)
                    }
                }
            } label: {
                Label(remindersData.upcomingRemindersInterval.rawValue, systemImage: "calendar")
            }
            .menuStyle(BorderlessButtonMenuStyle())
            .padding(.vertical, 5)
            .padding(.horizontal, 10)
            .background(intervalButtonIsHovered ? Color("buttonHover") : nil)
            .cornerRadius(6)
            .onHover { isHovered in
                intervalButtonIsHovered = isHovered
            }
            .padding(.trailing, 1)
            .fixedSize(horizontal: true, vertical: true)
            .help("Select range of upcoming reminders to be shown")
        }
    }
}

struct UpcomingRemindersTitle_Previews: PreviewProvider {
    static var previews: some View {
        UpcomingRemindersTitle().environmentObject(RemindersData())
    }
}
