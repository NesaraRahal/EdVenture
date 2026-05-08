import XCTest
@testable import EdVenture

final class EVQuizQuestionTests: XCTestCase {
    func testDictionaryRoundtrip() {
        let q = EVQuizQuestion(
            id: "q1",
            lessonId: "lessonA",
            level: 2,
            order: 3,
            difficulty: 23,
            xpMin: 1,
            xpMax: 10,
            xpSuggested: 5,
            prompt: "What is 2+2?",
            choices: ["3","4","5"],
            correctIndex: 1,
            explanation: "It's four",
            tags: ["math"],
            isActive: true
        )

        let dict = q.dictionary
        guard let recreated = EVQuizQuestion(id: q.id, data: dict) else {
            XCTFail("Recreation failed")
            return
        }

        XCTAssertEqual(recreated.id, q.id)
        XCTAssertEqual(recreated.prompt, q.prompt)
        XCTAssertEqual(recreated.choices.count, q.choices.count)
        XCTAssertEqual(recreated.correctIndex, q.correctIndex)
    }
}
