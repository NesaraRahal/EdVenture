import XCTest
@testable import EdVenture

final class EVCredentialStoreTests: XCTestCase {
    override func setUp() {
        super.setUp()
        EVCredentialStore.clear()
    }

    override func tearDown() {
        EVCredentialStore.clear()
        super.tearDown()
    }

    func testSaveLoadClearCredentials() {
        let saved = EVCredentialStore.save(email: "test@example.com", password: "p@ssw0rd")
        XCTAssertTrue(saved)

        guard let cred = EVCredentialStore.load() else {
            XCTFail("Expected credential to be loadable")
            return
        }

        XCTAssertEqual(cred.email, "test@example.com")
        XCTAssertEqual(cred.password, "p@ssw0rd")

        EVCredentialStore.clear()
        XCTAssertNil(EVCredentialStore.load())
    }
}
