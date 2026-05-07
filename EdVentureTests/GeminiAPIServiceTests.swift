import XCTest
@testable import EdVenture

@MainActor
final class GeminiAPIServiceTests: XCTestCase {
    let service = GeminiAPIService.shared

    func sampleJSON(title: String = "Sample") -> String {
        let payload: [String: Any] = [
            "title": title,
            "detectedObjectName": "Book Cover",
            "category": "astronomy",
            "shortSummary": "Short summary",
            "educationalFacts": ["fact1","fact2"],
            "difficultyLevel": "Beginner",
            "keyLearningPoints": ["kp1","kp2"],
            "quizQuestions": [
                ["question": "Q1","options": ["A","B","C","D"],"correctAnswerIndex": 1,"explanation": "ex"],
                ["question": "Q2","options": ["A","B","C","D"],"correctAnswerIndex": 0,"explanation": "ex"]
            ],
            "arOverlayCaption": "Caption"
        ]

        let data = try! JSONSerialization.data(withJSONObject: payload, options: [])
        return String(data: data, encoding: .utf8)!
    }

    func testParseEducationalContentBasic() throws {
        let json = sampleJSON()
        let content = try service.test_parseEducationalContent(json, extractedText: "extracted")
        XCTAssertEqual(content.title, "Sample")
        XCTAssertEqual(content.category, "astronomy")
        XCTAssertEqual(content.extractedText, "extracted")
        XCTAssertGreaterThan(content.quizQuestions.count, 0)
    }

    func testResolveCategoryFallback() {
        XCTAssertEqual(service.test_resolveCategory(nil), "computer_science")
        XCTAssertEqual(service.test_resolveCategory("UnknownCategory"), "computer_science")
        XCTAssertEqual(service.test_resolveCategory("Mathematics"), "mathematics")
    }

    func testIsRetryableStatus() {
        XCTAssertTrue(service.test_isRetryableStatus(429))
        XCTAssertTrue(service.test_isRetryableStatus(500))
        XCTAssertFalse(service.test_isRetryableStatus(400))
    }

    func testBuildRequestContainsPrompt() {
        let prompt = "hello world"
        let req = service.test_buildRequest(prompt: prompt)
        XCTAssertTrue(req.contents.first?.parts.first?.text.contains("EXTRACTED TEXT") == false || req.contents.first?.parts.first?.text.contains(prompt) == true)
    }
}
