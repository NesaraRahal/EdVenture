import XCTest
import AVFoundation
@testable import EdVenture

@MainActor
final class EVAccessibilitySupportTests: XCTestCase {
    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: EVAccessibilitySupport.hapticKey)
        UserDefaults.standard.removeObject(forKey: EVAccessibilitySupport.soundKey)
        UserDefaults.standard.removeObject(forKey: EVAccessibilitySupport.readerKey)
    }

    func testIsEnabledDefaultBehavior() {
        // When no value is set, default true should be returned
        XCTAssertTrue(EVAccessibilitySupport.isEnabled(EVAccessibilitySupport.hapticKey))
        XCTAssertTrue(EVAccessibilitySupport.isEnabled(EVAccessibilitySupport.soundKey))

        // If explicitly set to false, should return false
        UserDefaults.standard.set(false, forKey: EVAccessibilitySupport.soundKey)
        XCTAssertFalse(EVAccessibilitySupport.isEnabled(EVAccessibilitySupport.soundKey))
    }

    func testPlaySoundDoesNotCrashWhenDisabled() {
        UserDefaults.standard.set(false, forKey: EVAccessibilitySupport.soundKey)
        EVAccessibilitySupport.playSound(.click)
        // If we reach here without exceptions, behaviour is acceptable for unit test
        XCTAssertTrue(true)
    }
}
