import XCTest
@testable import EdVenture

@MainActor
final class LessonCooldownServiceTests: XCTestCase {
    let service = LessonCooldownService.shared

    func testCooldownSecondsRemaining() {
        let now = Date()
        let future = now.addingTimeInterval(3600 + 120) // 1h 2m
        let seconds = service.test_cooldownSecondsRemaining(expiresAt: future, now: now)
        XCTAssertNotNil(seconds)
        XCTAssertEqual(seconds, 3720, "Seconds remaining should equal interval")

        // expired
        let past = now.addingTimeInterval(-10)
        XCTAssertNil(service.test_cooldownSecondsRemaining(expiresAt: past, now: now))
        XCTAssertNil(service.test_cooldownSecondsRemaining(expiresAt: nil as Date?, now: now))
    }

    func testResolveLessonHelpers() {
        XCTAssertEqual(service.test_resolveLessonName("computer_science"), "Computer Science")
        XCTAssertEqual(service.test_resolveLessonIcon("astronomy"), "star.fill")
        XCTAssertEqual(service.test_resolveLessonColor("biology"), "27AE60")
        XCTAssertEqual(service.test_resolveLessonIcon("unknown_topic"), "book.fill")
    }

    func testLessonCooldownStatusDisplayString() {
        let statusNow = LessonCooldownStatus(lessonId: "a", lessonName: "A", lessonIcon: "i", lessonColorHex: "c", cooldownExpiresAt: nil, secondsRemaining: nil)
        XCTAssertEqual(statusNow.displayString, "Ready")

        let statusSoon = LessonCooldownStatus(lessonId: "b", lessonName: "B", lessonIcon: "i", lessonColorHex: "c", cooldownExpiresAt: Date().addingTimeInterval(70), secondsRemaining: 70)
        XCTAssertTrue(statusSoon.displayString.contains("m to go") || statusSoon.displayString == "Ready now!")
    }
}
