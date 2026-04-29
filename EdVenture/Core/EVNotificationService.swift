import Foundation
import UserNotifications
import FirebaseAuth
import FirebaseFirestore

enum EVNotificationApplyResult {
    case success
    case permissionDenied
    case permissionNotDetermined
}

struct EVNotificationPreferences {
    let pushEnabled: Bool
    let dailyReminders: Bool
    let streakReminders: Bool
    let weeklySummary: Bool
    let newContentAlerts: Bool

    static func fromDefaults(_ defaults: UserDefaults = .standard) -> EVNotificationPreferences {
        EVNotificationPreferences(
            pushEnabled: defaults.object(forKey: "notifications.pushEnabled") as? Bool ?? true,
            dailyReminders: defaults.object(forKey: "notifications.dailyReminders") as? Bool ?? true,
            streakReminders: defaults.object(forKey: "notifications.streakReminders") as? Bool ?? true,
            weeklySummary: defaults.object(forKey: "notifications.weeklySummary") as? Bool ?? true,
            newContentAlerts: defaults.object(forKey: "notifications.newContentAlerts") as? Bool ?? false
        )
    }
}

final class EVNotificationService {
    static let shared = EVNotificationService()

    private let center = UNUserNotificationCenter.current()

    private enum Id {
        static let daily = "ev.notifications.daily"
        static let streak = "ev.notifications.streak"
        static let weekly = "ev.notifications.weekly"
        static let newContent = "ev.notifications.newcontent"
        static let dailyGoalReminderPrefix = "ev.notifications.dailygoal.reminder"

        static let all = [daily, streak, weekly, newContent]
    }

    private init() {}

    func applyPreferences(_ prefs: EVNotificationPreferences,
                          requestAuthorizationIfNeeded: Bool) async -> EVNotificationApplyResult {
        if !prefs.pushEnabled {
            center.removePendingNotificationRequests(withIdentifiers: Id.all)
            center.removeDeliveredNotifications(withIdentifiers: Id.all)
            return .success
        }

        let status = await authorizationStatus()
        switch status {
        case .authorized, .provisional, .ephemeral:
            break
        case .notDetermined:
            guard requestAuthorizationIfNeeded else {
                center.removePendingNotificationRequests(withIdentifiers: Id.all)
                return .permissionNotDetermined
            }
            let granted = await requestAuthorization()
            guard granted else {
                center.removePendingNotificationRequests(withIdentifiers: Id.all)
                return .permissionDenied
            }
        case .denied:
            center.removePendingNotificationRequests(withIdentifiers: Id.all)
            return .permissionDenied
        @unknown default:
            center.removePendingNotificationRequests(withIdentifiers: Id.all)
            return .permissionDenied
        }

        center.removePendingNotificationRequests(withIdentifiers: Id.all)

        if prefs.dailyReminders {
            await scheduleDailyLearningReminder()
        }

        if prefs.streakReminders {
            await scheduleStreakReminder()
        }

        if prefs.weeklySummary {
            await scheduleWeeklySummary()
        }

        if prefs.newContentAlerts {
            await scheduleNewContentAlert()
        }

        return .success
    }

    private func authorizationStatus() async -> UNAuthorizationStatus {
        await withCheckedContinuation { continuation in
            center.getNotificationSettings { settings in
                continuation.resume(returning: settings.authorizationStatus)
            }
        }
    }

    private func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }

    private func scheduleDailyLearningReminder() async {
        let content = UNMutableNotificationContent()
        content.title = "Daily Learning Reminder"
        content.body = "Keep your streak alive. Take one quick lesson today."
        content.sound = .default

        var date = DateComponents()
        date.hour = 19
        date.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
        let request = UNNotificationRequest(identifier: Id.daily, content: content, trigger: trigger)
        try? await center.add(request)
    }

    private func scheduleStreakReminder() async {
        let content = UNMutableNotificationContent()
        content.title = "Streak Reminder"
        content.body = "You are on a roll. Don’t break your learning streak today."
        content.sound = .default

        var date = DateComponents()
        date.hour = 21
        date.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
        let request = UNNotificationRequest(identifier: Id.streak, content: content, trigger: trigger)
        try? await center.add(request)
    }

    private func scheduleWeeklySummary() async {
        let content = UNMutableNotificationContent()
        content.title = "Weekly Progress Summary"
        content.body = "Your weekly learning summary is ready. Check your progress."
        content.sound = .default

        var date = DateComponents()
        date.weekday = 1 // Sunday
        date.hour = 18
        date.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
        let request = UNNotificationRequest(identifier: Id.weekly, content: content, trigger: trigger)
        try? await center.add(request)
    }

    private func scheduleNewContentAlert() async {
        let content = UNMutableNotificationContent()
        content.title = "New Content Available"
        content.body = "Fresh lessons are available. Explore something new today."
        content.sound = .default

        var date = DateComponents()
        date.weekday = 3 // Tuesday
        date.hour = 10
        date.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
        let request = UNNotificationRequest(identifier: Id.newContent, content: content, trigger: trigger)
        try? await center.add(request)
    }

    // MARK: - One-off notifications

    func sendInstantNotification(title: String,
                                 body: String,
                                 identifierPrefix: String = "ev.notifications.instant",
                                 delaySeconds: TimeInterval = 1.0) async -> Bool {
        let pushEnabled = UserDefaults.standard.object(forKey: "notifications.pushEnabled") as? Bool ?? true
        guard pushEnabled else { return false }

        let status = await authorizationStatus()
        switch status {
        case .authorized, .provisional, .ephemeral:
            break
        case .notDetermined:
            let granted = await requestAuthorization()
            guard granted else { return false }
        case .denied:
            return false
        @unknown default:
            return false
        }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, delaySeconds), repeats: false)
        let identifier = "\(identifierPrefix).\(UUID().uuidString)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        do {
            try await center.add(request)
            return true
        } catch {
            return false
        }
    }

    func sendLessonAddedNotification(lessonTitle: String) async {
        _ = await sendInstantNotification(
            title: "Lesson Added to Practice",
            body: "📚 \(lessonTitle) is ready to practice.",
            identifierPrefix: "ev.notifications.lesson.added",
            delaySeconds: 2.0
        )
    }

    func sendDailyGoalCompletedNotification(goalMinutes: Int) async {
        _ = await sendInstantNotification(
            title: "Daily Goal Completed",
            body: "Great work. You reached your \(goalMinutes)-minute learning goal today.",
            identifierPrefix: "ev.notifications.dailygoal.completed",
            delaySeconds: 1.5
        )
    }

    func updateDailyGoalReminder(goalMinutes: Int,
                                 progressSeconds: Int,
                                 completed: Bool) async {
        let pushEnabled = UserDefaults.standard.object(forKey: "notifications.pushEnabled") as? Bool ?? true
        let dailyRemindersEnabled = UserDefaults.standard.object(forKey: "notifications.dailyReminders") as? Bool ?? true

        guard pushEnabled, dailyRemindersEnabled else {
            await cancelTodayDailyGoalReminder()
            return
        }

        if completed || progressSeconds >= goalMinutes * 60 {
            await cancelTodayDailyGoalReminder()
        } else {
            await scheduleToday8PMDailyGoalReminder(goalMinutes: goalMinutes)
        }
    }

    func refreshDailyGoalReminderForCurrentUser() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        do {
            let snapshot = try await Firestore.firestore().collection("users").document(uid).getDocument()
            let data = snapshot.data() ?? [:]

            let goalMinutes = data["dailyGoalMinutes"] as? Int ?? 10
            let progressSeconds = data["dailyProgressSeconds"] as? Int ?? 0
            let completed = data["dailyGoalCompleted"] as? Bool ?? false

            await updateDailyGoalReminder(
                goalMinutes: goalMinutes,
                progressSeconds: progressSeconds,
                completed: completed
            )
        } catch {
            // Keep silent to avoid breaking app flows.
        }
    }

    private func scheduleToday8PMDailyGoalReminder(goalMinutes: Int) async {
        let now = Date()
        let calendar = Calendar.current

        guard let today8PM = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: now),
              today8PM > now else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Daily Goal Reminder"
        content.body = "It is 8:00 PM. You still have time to hit your \(goalMinutes)-minute goal today."
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: calendar.dateComponents([.year, .month, .day, .hour, .minute], from: today8PM),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: todayDailyGoalReminderId(),
            content: content,
            trigger: trigger
        )

        try? await center.add(request)
    }

    private func cancelTodayDailyGoalReminder() async {
        center.removePendingNotificationRequests(withIdentifiers: [todayDailyGoalReminderId()])
    }

    private func todayDailyGoalReminderId() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-MM-dd"
        return "\(Id.dailyGoalReminderPrefix).\(formatter.string(from: Date()))"
    }
}
