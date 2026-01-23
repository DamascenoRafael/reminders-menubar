import SwiftUI
import EventKit
import Combine

struct CalendarEventsBlockView: View {
    @ObservedObject var userPreferences = UserPreferences.shared
    
    @State private var events: [EKEvent] = []
    
    var body: some View {
        Group {
            if !events.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(events, id: \.eventIdentifier) { event in
                        CalendarEventRow(event: event)
                    }
                }
                .padding(8)
                .background(Color.primary.opacity(0.05))
                .cornerRadius(6)
                .padding(.horizontal, 4)
                .padding(.bottom, 4)
            }
        }
        .onAppear {
            loadEvents()
        }
        .onChange(of: userPreferences.eventCalendarIdentifiersFilter) { _ in
            loadEvents()
        }
        .onChange(of: userPreferences.remindersMenuBarOpeningEvent) { _ in
            // Reload when app window opens
            loadEvents()
        }
        .onReceive(NotificationCenter.default.publisher(for: .EKEventStoreChanged)) { _ in
            loadEvents()
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            loadEvents()
        }
    }
    
    private func loadEvents() {
        // Check authorization first
        let status = CalendarEventsService.shared.authorizationStatus()
        let isAuthorized: Bool
        if #available(macOS 14.0, *) {
            isAuthorized = status == .fullAccess
        } else {
            isAuthorized = status == .authorized
        }
        
        guard isAuthorized else { return }
        
        events = CalendarEventsService.shared.getTodayEvents(
            for: userPreferences.eventCalendarIdentifiersFilter
        )
    }
}

struct CalendarEventRow: View {
    let event: EKEvent
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 4) {
            if event.isAllDay {
                Circle()
                    .fill(Color(event.calendar.color))
                    .frame(width: 6, height: 6)
            } else {
                Text(timeString)
                    .foregroundColor(Color(event.calendar.color))
            }
            
            Text(event.title)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .font(.system(size: 9))
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 1)
        .padding(.horizontal, 4)
        .background(isHovered ? Color.primary.opacity(0.08) : Color.clear)
        .cornerRadius(3)
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            CalendarEventsService.shared.openEventInCalendar(event)
        }
    }
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: event.startDate)
    }
}

#Preview {
    CalendarEventsBlockView()
}
