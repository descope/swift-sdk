import XCTest
@testable import DescopeKit

class TestUser: XCTestCase {
    func testUserEncoding() throws {
        var user = DescopeUser(
            userId: "userId",
            loginIds: ["loginId"],
            createdAt: Date(),
            email: "email",
            isVerifiedEmail: true,
            customAttributes: ["a": "yes"]
        )

        let encodedUser = try JSONEncoder().encode(user)
        let decodedUser = try JSONDecoder().decode(DescopeUser.self, from: encodedUser)

        XCTAssertTrue(decodedUser.isVerifiedEmail)
        XCTAssertFalse(decodedUser.isVerifiedPhone)
        guard let aValue = decodedUser.customAttributes["a"] as? String else { return XCTFail("Couldn't get custom attribute value as String") }
        XCTAssertEqual("yes", aValue)

        XCTAssertEqual(user, decodedUser)
        XCTAssertTrue(user == decodedUser)

        user.customAttributes["a"] = TestUser()
        XCTAssertNotEqual(user, decodedUser)
        XCTAssertTrue(user != decodedUser)

        user.customAttributes["a"] = "no"
        XCTAssertNotEqual(user, decodedUser)
        XCTAssertTrue(user != decodedUser)

        user.customAttributes["a"] = "yes"
        XCTAssertEqual(user, decodedUser)
        XCTAssertTrue(user == decodedUser)
    }
}
