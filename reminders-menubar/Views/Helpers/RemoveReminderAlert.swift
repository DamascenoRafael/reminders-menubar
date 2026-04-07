import SwiftUI
import EventKit

@MainActor
func removeReminderAlert(for reminder: EKReminder, onRemove: (() -> Void)? = nil) -> Alert {
    Alert(
        title: Text(rmbLocalized(.removeReminderAlertTitle)),
        message: Text(rmbLocalized(.removeReminderAlertMessage, arguments: reminder.title)),
        primaryButton: .destructive(Text(rmbLocalized(.removeReminderAlertConfirmButton)), action: {
            MainActor.assumeIsolated {
                RemindersService.shared.remove(reminder: reminder)
                onRemove?()
            }
        }),
        secondaryButton: .cancel(Text(rmbLocalized(.removeReminderAlertCancelButton)))
    )
}
