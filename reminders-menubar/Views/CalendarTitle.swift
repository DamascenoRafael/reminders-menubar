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
                .font(.subheadline.weight(.semibold))
                .foregroundColor(Color(calendar.color).opacity(0.8))
                .padding(.bottom, 2)
            
            Spacer()
            
            Button(action: {
                remindersData.calendarForSaving = calendar
            }) {
                let isSelected = remindersData.calendarForSaving?.calendarIdentifier == calendar.calendarIdentifier
                Image(systemName: isSelected ? "folder.fill" : "folder")
                    .font(Font.caption.weight(.medium))
                    .foregroundColor(calendarFolderIsHovered ? Color(calendar.color) : nil)
                    .frame(width: 12, height: 12, alignment: .center)
                    .padding(4)
            }
            .buttonStyle(BorderlessButtonStyle())
            .background(calendarFolderIsHovered ? Color.rmbColor(for: .buttonHover, and: colorSchemeContrast) : nil)
            .cornerRadius(4)
            .onHover { isHovered in
                calendarFolderIsHovered = isHovered
            }
            .padding(.horizontal, 4)
            .help(rmbLocalized(.selectListForSavingReminderButtonHelp))
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
