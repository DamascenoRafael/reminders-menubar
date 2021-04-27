import SwiftUI
import EventKit

struct CalendarTitleView: View {
    @ObservedObject var userPreferences = UserPreferences.instance
    
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
                userPreferences.calendarForSaving = calendar
            }) {
                let isSelected = userPreferences.calendarForSaving.calendarIdentifier == calendar.calendarIdentifier
                Image(systemName: isSelected ? "folder.fill" : "folder")
                    .font(Font.headline.weight(.medium))
                    .foregroundColor(calendarFolderIsHovered ? Color(calendar.color): nil)
                    .frame(width: 15, height: 15, alignment: .center)
                    .padding(5)
            }
            .buttonStyle(BorderlessButtonStyle())
            .background(calendarFolderIsHovered ? Color("buttonHover") : nil)
            .cornerRadius(6)
            .onHover { isHovered in
                calendarFolderIsHovered = isHovered
            }
            .padding(.horizontal, 7.5)
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
                CalendarTitleView(calendar: calendar)
                    .colorScheme(color)
                    .previewDisplayName("\(color) mode")
            }
        }
    }
}
