import Combine
import EventKit

@MainActor
class MenuBarPreviewService {
    private static let nowGracePeriod: TimeInterval = 5 * 60

    private var cancellationTokens: [AnyCancellable] = []
    private var timer: Timer?
    private var cachedReminders: [ReminderItem] = []

    init() {
        observePreviewPreferences()
    }

    private func observePreviewPreferences() {
        Publishers.MergeMany(
            UserPreferences.shared.$menuBarReminderPreviewTimeAhead.map { _ in }.eraseToAnyPublisher(),
            UserPreferences.shared.$menuBarReminderPreviewMaxLength.map { _ in }.eraseToAnyPublisher(),
            UserPreferences.shared.$hideCounterWhenReminderPreviewIsShown.map { _ in }.eraseToAnyPublisher(),
            UserPreferences.shared.$menuBarReminderPreviewShowTodayReminders.map { _ in }.eraseToAnyPublisher()
        )
        .dropFirst()
        .sink { [weak self] _ in
            Task { [weak self] in
                guard let self else { return }
                self.recompute()
            }
        }
        .store(in: &cancellationTokens)
    }

    func refresh(calendarFilter: [String]?) async {
        guard UserPreferences.shared.menuBarReminderPreviewEnabled else {
            cachedReminders = []
            stopTimer()
            AppDelegate.shared.updateMenuBarReminderPreview(nil)
            return
        }

        cachedReminders = await RemindersService.shared.getUpcomingReminders(.week, for: calendarFilter)
        recompute()
    }

    private func recompute() {
        let now = Date()
        let title = getFormattedPreview(now: now)
        AppDelegate.shared.updateMenuBarReminderPreview(title)
        scheduleNextUpdate(now: now)
    }

    private func getFormattedPreview(now: Date) -> String? {
        if let reminder = findNearestTimedCandidate(now: now) ?? findTodayUntimedReminder() {
            return formatPreview(for: reminder, now: now)
        }
        return nil
    }

    private func findNearestTimedCandidate(now: Date) -> EKReminder? {
        let timeAhead = UserPreferences.shared.menuBarReminderPreviewTimeAhead.timeInterval

        var bestFuture: (EKReminder, Date)?
        var bestGracePeriod: (EKReminder, Date)?

        for item in cachedReminders {
            let reminder = item.reminder
            guard reminder.hasTime, let dueDate = reminder.dueDateComponents?.date else { continue }

            let timeUntilDue = dueDate.timeIntervalSince(now)

            if timeUntilDue >= 0 {
                // Future reminder: include if within the time-ahead window, keep the soonest
                guard timeUntilDue <= timeAhead else { continue }
                if dueDate < (bestFuture?.1 ?? .distantFuture) {
                    bestFuture = (reminder, dueDate)
                }
            } else {
                // Past reminder: include if within grace period, keep the most recently due
                guard (-timeUntilDue) <= Self.nowGracePeriod else { continue }
                if dueDate > (bestGracePeriod?.1 ?? .distantPast) {
                    bestGracePeriod = (reminder, dueDate)
                }
            }
        }

        // NOTE: Future reminders take priority over grace-period ones.
        return (bestFuture ?? bestGracePeriod)?.0
    }

    private func findTodayUntimedReminder() -> EKReminder? {
        guard UserPreferences.shared.menuBarReminderPreviewShowTodayReminders else {
            return nil
        }

        return cachedReminders.first(where: { isUntimedReminderDueToday($0.reminder) })?.reminder
    }

    private func isUntimedReminderDueToday(_ reminder: EKReminder) -> Bool {
        guard let dueDate = reminder.dueDateComponents?.date else { return false }
        return !reminder.hasTime && dueDate.isToday
    }

    private func formatPreview(for reminder: EKReminder, now: Date) -> String? {
        guard let dueDate = reminder.dueDateComponents?.date else {
            return nil
        }

        let title = truncateTitle(reminder.title ?? "")

        let prefix: String
        if !reminder.hasTime {
            prefix = rmbLocalized(.menuBarPreviewTodayPrefix)
        } else {
            let secondsUntilDue = dueDate.timeIntervalSince(now)
            if secondsUntilDue <= 0 {
                prefix = rmbLocalized(.menuBarPreviewNowPrefix)
            } else {
                prefix = formatTimePrefix(seconds: secondsUntilDue)
            }
        }

        return "\(prefix): \(title)"
    }

    private func truncateTitle(_ title: String) -> String {
        let maxLength = UserPreferences.shared.menuBarReminderPreviewMaxLength
        // Don't truncate if we'd only save one character (the ellipsis will replace it).
        guard title.count > maxLength + 1 else {
            return title
        }
        let endIndex = title.index(title.startIndex, offsetBy: maxLength)
        return String(title[..<endIndex]) + "…"
    }

    private func formatTimePrefix(seconds: TimeInterval) -> String {
        let totalMinutes = Int(ceil(seconds / 60))
        if totalMinutes < 60 {
            return "\(totalMinutes)m"
        }
        let hours = totalMinutes / 60
        return "\(hours)h"
    }

    // MARK: - Timer scheduling

    private func scheduleNextUpdate(now: Date) {
        stopTimer()

        guard let nextFire = computeNextFireDate(for: cachedReminders, now: now) else {
            return
        }

        // NOTE: Add a small buffer (0.5s) to ensure we land past the transition boundary.
        let fireDate = nextFire.addingTimeInterval(0.5)
        let timer = Timer(fire: fireDate, interval: 0, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.recompute()
            }
        }
        timer.tolerance = 1.0
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func computeNextFireDate(for reminders: [ReminderItem], now: Date) -> Date? {
        var nextDates: [Date] = []

        let timeAhead = UserPreferences.shared.menuBarReminderPreviewTimeAhead.timeInterval

        for item in reminders {
            let reminder = item.reminder
            guard reminder.hasTime, let dueDate = reminder.dueDateComponents?.date else {
                continue
            }
            nextDates.append(contentsOf: transitionDates(for: dueDate, now: now, timeAhead: timeAhead))
        }

        return nextDates.filter({ $0 > now }).min()
    }

    private func transitionDates(for dueDate: Date, now: Date, timeAhead: TimeInterval) -> [Date] {
        var dates: [Date] = []
        let timeUntilDue = dueDate.timeIntervalSince(now)

        // Time ahead entry: reminder not yet in window, will enter at (dueDate - timeAhead).
        let timeAheadEntry = dueDate.addingTimeInterval(-timeAhead)
        if timeAhead > 0 && timeAheadEntry > now {
            dates.append(timeAheadEntry)
        }

        // Prefix changes from countdown to "Now" when the due date arrives.
        if timeUntilDue > 0 {
            dates.append(dueDate)
        }

        // Grace period exit: reminder disappears from preview
        let graceExit = dueDate.addingTimeInterval(Self.nowGracePeriod)
        if graceExit > now {
            dates.append(graceExit)
        }

        // Next prefix change: fire when the displayed countdown label would update.
        if timeUntilDue > 0 && timeUntilDue <= timeAhead {
            let totalMinutes = Int(ceil(timeUntilDue / 60))
            let nextLabelMinutes = totalMinutes - 1
            let nextChangeDate = dueDate.addingTimeInterval(Double(-nextLabelMinutes) * 60)
            if nextChangeDate > now {
                dates.append(nextChangeDate)
            }
        }

        return dates
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
