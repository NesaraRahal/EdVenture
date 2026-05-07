import XCTest
@testable import EdVenture

final class EVNotificationServiceTests: XCTestCase {
    func testNotificationPreferencesFromDefaults() {
        let suiteName = "test.notifications.prefs"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        defaults.set(false, forKey: "notifications.pushEnabled")
        defaults.set(true, forKey: "notifications.dailyReminders")
        defaults.set(false, forKey: "notifications.weeklySummary")
        defaults.set(true, forKey: "notifications.streakReminders")
        defaults.set(true, forKey: "notifications.newContentAlerts")

        let prefs = EVNotificationPreferences.fromDefaults(defaults)
        XCTAssertFalse(prefs.pushEnabled)
        XCTAssertTrue(prefs.dailyReminders)
        XCTAssertFalse(prefs.weeklySummary)
        XCTAssertTrue(prefs.streakReminders)
        XCTAssertTrue(prefs.newContentAlerts)

        defaults.removePersistentDomain(forName: suiteName)
    }

    func testTodayDailyGoalReminderIdFormat() {
        let service = EVNotificationService.shared
        let id = service.test_todayDailyGoalReminderId()
        XCTAssertTrue(id.hasPrefix("ev.notifications.dailygoal.reminder."))
        let suffix = id.split(separator: ".").last
        XCTAssertNotNil(suffix)
        XCTAssertEqual(suffix!.count, 10) // yyyy-MM-dd
    }
}
