import XCTest
@testable import EdVenture

final class EVTelemetryModeTests: XCTestCase {
    func testTitlesAndDetails() {
        XCTAssertEqual(EVTelemetryMode.importantOnly.title, "Important Logs Only")
        XCTAssertTrue(EVTelemetryMode.importantOnly.detail.contains("crash"))

        XCTAssertEqual(EVTelemetryMode.businessValue.title, "Important + Business")
        XCTAssertTrue(EVTelemetryMode.businessValue.detail.contains("business"))
    }
}
