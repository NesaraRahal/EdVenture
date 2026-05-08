import XCTest
@testable import EdVenture

final class EVQuizSessionStateTests: XCTestCase {
    func makeQuestion(id: String = "q1", order: Int = 1) -> EVQuizQuestion {
        EVQuizQuestion(
            id: id,
            lessonId: "lesson1",
            level: 1,
            order: order,
            difficulty: 1,
            xpMin: 1,
            xpMax: 5,
            xpSuggested: 3,
            prompt: "prompt",
            choices: ["a", "b"],
            correctIndex: 0,
            explanation: "exp"
        )
    }

    func testInitialAndNextQuestionIndex() {
        let s = EVQuizSessionState.initial(lessonId: "l", level: 1, totalQuestions: 10)
        XCTAssertEqual(s.currentQuestionIndex, 0)
        XCTAssertEqual(s.nextQuestionIndex, 1)
        XCTAssertEqual(s.unlockedCount, 1)
    }

    func testWithLoadedWindowResetsExpiredWindowAndRetry() {
        var s = EVQuizSessionState.initial(lessonId: "l", level: 1, totalQuestions: 5)
        s.windowStartsAt = Date(timeIntervalSince1970: 0)
        s.correctInWindow = 5
        s.lockedUntil = Date(timeIntervalSince1970: 1)
        s.retryAvailableUntil = Date(timeIntervalSince1970: 1)
        s.retryQuestions = [EVQuizRetryQuestion(questionIndex: 0, question: makeQuestion())]

        let now = Date(timeIntervalSince1970: 10000)
        let loaded = s.withLoadedWindow(now: now)

        XCTAssertEqual(loaded.correctInWindow, 0)
        XCTAssertNil(loaded.lockedUntil)
        XCTAssertNil(loaded.retryAvailableUntil)
        XCTAssertTrue(loaded.retryQuestions.isEmpty)
    }

    func testAddRemoveRetryAndActiveRetryQuestionsOrdering() {
        var s = EVQuizSessionState.initial(lessonId: "l", level: 1, totalQuestions: 5)
        let q1 = makeQuestion(id: "q1", order: 2)
        let q2 = makeQuestion(id: "q2", order: 1)

        s.addRetryQuestion(q1, questionIndex: 1, now: Date())
        s.addRetryQuestion(q2, questionIndex: 1, now: Date())

        let active = s.activeRetryQuestions
        XCTAssertEqual(active.count, 2)
        XCTAssertEqual(active[0].question.id, "q2")

        s.removeRetryQuestion(questionId: "q2")
        XCTAssertEqual(s.retryQuestions.count, 1)
        XCTAssertEqual(s.retryQuestions[0].question.id, "q1")
    }

    func testApplyCorrectAndWrongAnswersUpdateSession() {
        var s = EVQuizSessionState.initial(lessonId: "l", level: 1, totalQuestions: 3)
        let q = makeQuestion(id: "q1")

        s.applyCorrectAnswer(questionId: q.id, xpEarned: 5, totalQuestions: 3, now: Date())
        XCTAssertEqual(s.attemptedCount, 1)
        XCTAssertEqual(s.consecutiveWins, 1)
        XCTAssertTrue(s.completedQuestionIDs.contains(q.id))

        s.applyWrongAnswer(totalQuestions: 3, now: Date())
        XCTAssertEqual(s.attemptedCount, 2)
        XCTAssertEqual(s.consecutiveWins, 0)
    }
}
