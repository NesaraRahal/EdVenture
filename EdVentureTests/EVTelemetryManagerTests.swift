import XCTest
@testable import EdVenture

final class EVTelemetryManagerTests: XCTestCase {
    func testSanitizeEventName() {
        let raw = "My Event! @Home #1"
        let cleaned = EVTelemetryManager.test_sanitizeAnalyticsEventName(raw)
        XCTAssertFalse(cleaned.contains(" "))
        XCTAssertFalse(cleaned.contains("!"))
        XCTAssertTrue(cleaned.count <= 40)
    }

    func testSanitizeEventNameStartsWithNumber() {
        let raw = "1stEvent"
        let cleaned = EVTelemetryManager.test_sanitizeAnalyticsEventName(raw)
        XCTAssertTrue(cleaned.hasPrefix("ev_") || cleaned.first?.isNumber == false)
    }

    func testSanitizeKey() {
        let raw = "User-Email@Address"
        let cleaned = EVTelemetryManager.test_sanitizeAnalyticsKey(raw)
        XCTAssertFalse(cleaned.contains("@"))
        XCTAssertFalse(cleaned.contains("-"))
        XCTAssertTrue(cleaned.count <= 24)
    }
}
