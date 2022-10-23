import XCTest
@testable import DescopeKit

final class Tests: XCTestCase {
    func testExample() throws {
        let descopeSdk = DescopeSDK()
        XCTAssertEqual(descopeSdk.config.projectId, "")
    }
}
