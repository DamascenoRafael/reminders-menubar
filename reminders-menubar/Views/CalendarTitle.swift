import SwiftUI
import EventKit

struct CalendarTitle: View {
    @EnvironmentObject var remindersData: RemindersData
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    
    var calendar: EKCalendar
    @State var calendarFolderIsHovered = false
    
    var body: some View {
        HStack(alignment: .center) {
            Text(calendar.title)
                .font(.headline)
                .foregroundColor(Color(calendar.color))
                .padding(.bottom, 5)
            
            Spacer()
            
            Button(action: {
                remindersData.calendarForSaving = calendar
            }) {
                let isSelected = remindersData.calendarForSaving?.calendarIdentifier == calendar.calendarIdentifier
                Image(systemName: isSelected ? "folder.fill" : "folder")
                    .font(Font.headline.weight(.medium))
                    .foregroundColor(calendarFolderIsHovered ? Color(calendar.color) : nil)
                    .frame(width: 15, height: 15, alignment: .center)
                    .padding(5)
            }
            .buttonStyle(BorderlessButtonStyle())
            .background(calendarFolderIsHovered ? Color.rmbColor(for: .buttonHover, and: colorSchemeContrast) : nil)
            .cornerRadius(6)
            .onHover { isHovered in
                calendarFolderIsHovered = isHovered
            }
            .padding(.horizontal, 7.5)
            .help(rmbLocalized(.createNewRemindersHereHelp))
        }
    }
}

struct CalendarTitleView_Previews: PreviewProvider {
    static var calendar: EKCalendar {
        let calendar = EKCalendar(for: .reminder, eventStore: .init())
        calendar.title = "Reminders"
        calendar.color = .systemTeal
        
        return calendar
    }
    
    static var previews: some View {
        Group {
            ForEach(ColorScheme.allCases, id: \.self) { color in
                CalendarTitle(calendar: calendar)
                    .colorScheme(color)
                    .previewDisplayName("\(color) mode")
            }
        }
    }
}
