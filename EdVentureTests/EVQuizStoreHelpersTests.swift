import XCTest
@testable import EdVenture

final class EVQuizStoreHelpersTests: XCTestCase {
    let store = EVQuizStore()

    func testParseLevelOrder() {
        XCTAssertEqual(store.test_parseLevelOrder(from: "lesson_L01_Q05")?.level, 1)
        XCTAssertEqual(store.test_parseLevelOrder(from: "lesson_L12_Q10")?.level, 12)
        XCTAssertNil(store.test_parseLevelOrder(from: "invalid_format"))
    }

    func testSessionDocumentIdAndLevelSetId() {
        XCTAssertEqual(store.test_sessionDocumentId(lessonId: "lesson", level: 3), "lesson_L03")
        XCTAssertEqual(store.test_sessionDocumentId(lessonId: "lesson", level: 0), "lesson_L01")
    }

    func testDayKeyFormatting() {
        let now = Date()
        let key = store.test_dayKey(now)
        XCTAssertTrue(key.count == 10)
    }

    func testShuffledByDifficultyOrdering() {
        let q1 = EVQuizQuestion(id: "q1", lessonId: "l", level: 1, order: 2, difficulty: 5, xpMin: 1, xpMax: 2, xpSuggested: 1, prompt: "p", choices: ["a","b"], correctIndex: 0, explanation: "e")
        let q2 = EVQuizQuestion(id: "q2", lessonId: "l", level: 1, order: 1, difficulty: 5, xpMin: 1, xpMax: 2, xpSuggested: 1, prompt: "p", choices: ["a","b"], correctIndex: 0, explanation: "e")
        let q3 = EVQuizQuestion(id: "q3", lessonId: "l", level: 1, order: 1, difficulty: 3, xpMin: 1, xpMax: 2, xpSuggested: 1, prompt: "p", choices: ["a","b"], correctIndex: 0, explanation: "e")

        let ordered = store.test_shuffledByDifficulty([q1,q2,q3])
        // difficulty ascending: q3(d3) then q2/q1(d5) with order tiebreaker
        XCTAssertEqual(ordered.first?.id, "q3")
        XCTAssertTrue(ordered[1].order <= ordered[2].order)
    }
}
