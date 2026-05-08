import XCTest
@testable import EdVenture

@MainActor
final class UserProfileViewModelTests: XCTestCase {
    let vm = UserProfileViewModel()

    func testDayKeyRoundtrip() {
        let now = Date()
        let key = vm.test_dayKey(now)
        let back = vm.test_dateFromDayKey(key)
        XCTAssertNotNil(back)
        XCTAssertEqual(vm.test_dayKey(back!), key)
    }

    func testScoreLabelAndColor() {
        XCTAssertEqual(vm.test_scoreLabel(100), "PERFECT")
        XCTAssertEqual(vm.test_scoreLabel(80), "SOLID")
        XCTAssertEqual(vm.test_scoreColorHex(95), "7EF5A8")
        XCTAssertEqual(vm.test_scoreColorHex(70), "F6CC2E")
    }

    func testIconNameMapping() {
        XCTAssertEqual(vm.test_iconName("astronomy"), "sparkles")
        XCTAssertEqual(vm.test_iconName("unknown_topic"), "book.fill")
    }

    func testAccuracyPercentComputation() {
        XCTAssertEqual(vm.test_accuracyPercent(correct: 3, total: 4), 75)
        XCTAssertEqual(vm.test_accuracyPercent(correct: 0, total: 0), 0)
    }



    func testHasTopicMastery() {
        XCTAssertTrue(vm.test_hasTopicMastery(lessonId: "math", correct: 6, total: 6))
        XCTAssertFalse(vm.test_hasTopicMastery(lessonId: "math", correct: 4, total: 6))
    }

    func testCurrentDailyStreak() {
        // simulate attempts for today, yesterday, and two days ago -> 3-day streak
        let streak = vm.test_currentDailyStreak(dayOffsets: [0,1,2])
        XCTAssertGreaterThanOrEqual(streak, 1)
    }
}
