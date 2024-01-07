import XCTest
@testable import DescopeKit

class TestUser: XCTestCase {
    func testUserEncoding() throws {
        let user = DescopeUser(userId: "userId", loginIds: ["loginId"], createdAt: Date(), email: "email", isVerifiedEmail: true, customAttributes: ["a": "yes"])
        let encodedUser = try JSONEncoder().encode(user)
        let decodedUser = try JSONDecoder().decode(DescopeUser.self, from: encodedUser)
        XCTAssertEqual(user, decodedUser)
        XCTAssertTrue(decodedUser.isVerifiedEmail)
        XCTAssertFalse(decodedUser.isVerifiedPhone)
        guard let aValue = decodedUser.customAttributes["a"] as? String else { return XCTFail("Couldn't get custom attirubte value as String") }
        XCTAssertEqual("yes", aValue)
    }
}
