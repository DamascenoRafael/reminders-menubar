import EventKit
import AppKit

@MainActor
class CalendarEventsService {
    static let shared = CalendarEventsService()
    
    private init() {
        // This prevents others from using the default '()' initializer for this class.
    }
    
    private let eventStore = EKEventStore()
    
    func authorizationStatus() -> EKAuthorizationStatus {
        return EKEventStore.authorizationStatus(for: .event)
    }
    
    func requestAccess() async -> Bool {
        if #available(macOS 14.0, *) {
            do {
                return try await eventStore.requestFullAccessToEvents()
            } catch {
                print("Error requesting calendar access:", error.localizedDescription)
                return false
            }
        } else {
            return await withCheckedContinuation { continuation in
                eventStore.requestAccess(to: .event) { granted, error in
                    if let error {
                        print("Error requesting calendar access:", error.localizedDescription)
                    }
                    continuation.resume(returning: granted)
                }
            }
        }
    }
    
    func getEventCalendars() -> [EKCalendar] {
        return eventStore.calendars(for: .event)
    }
    
    func getTodayEvents(for calendarIdentifiers: [String]) -> [EKEvent] {
        guard !calendarIdentifiers.isEmpty else { return [] }
        
        let calendars = getEventCalendars().filter { calendarIdentifiers.contains($0.calendarIdentifier) }
        guard !calendars.isEmpty else { return [] }
        
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
        
        let predicate = eventStore.predicateForEvents(
            withStart: startOfDay,
            end: endOfDay,
            calendars: calendars
        )
        
        return eventStore.events(matching: predicate).sorted { event1, event2 in
            // All-day events first, then by start date
            if event1.isAllDay != event2.isAllDay {
                return event1.isAllDay
            }
            return event1.startDate < event2.startDate
        }
    }
    
    func openEventInCalendar(_ event: EKEvent) {
        // Open Calendar app at the event's date
        if let url = URL(string: "ical://") {
            NSWorkspace.shared.open(url)
        }
    }
}
