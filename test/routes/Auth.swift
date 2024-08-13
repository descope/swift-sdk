import XCTest
@testable import DescopeKit

class TestAuth: XCTestCase {
    func testMe() async throws {
        let descope = DescopeSDK.mock()

        MockHTTP.push(body: userPayload) { request in
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.allHTTPHeaderFields?["Authorization"], "Bearer projId:jwt")
        }

        let user = try await descope.auth.me(refreshJwt: "jwt")

        try checkUser(user)
    }

    func testAuth() async throws {
        let descope = DescopeSDK.mock()

        MockHTTP.push(body: authPayload) { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.url?.absoluteString ?? "", "https://api.descope.com/v1/auth/otp/verify/email")
            XCTAssertEqual(request.allHTTPHeaderFields?["Authorization"], "Bearer projId")
        }

        let authResponse = try await descope.otp.verify(with: .email, loginId: "foo", code: "123456")
        XCTAssertEqual("bar", authResponse.sessionToken.entityId)
        XCTAssertEqual("qux", authResponse.refreshToken.entityId)
        XCTAssertTrue(authResponse.isFirstAuthentication)

        try checkUser(authResponse.user)
    }

    func checkUser(_ user: DescopeUser) throws {
        XCTAssertEqual("userId", user.userId)
        XCTAssertFalse(user.isVerifiedPhone)
        XCTAssertTrue(user.isVerifiedEmail)
        XCTAssertNil(user.givenName)

        // customAttributes
        try checkDictionary(user.customAttributes)

        // customAttributes.unnecessaryArray
        guard let array = user.customAttributes["unnecessaryArray"] as? [Any] else { return XCTFail() }
        try checkArray(array)

        // customAttributes.unnecessaryArray[3]
        guard let dict = array[3] as? [String: Any] else { return XCTFail() }
        try checkDictionary(dict)
    }

    func checkDictionary(_ dict: [String: Any]) throws {
        XCTAssertEqual("yes", dict["a"] as? String)
        XCTAssertEqual(true, dict["b"] as? Bool)
        XCTAssertEqual(1, dict["c"] as? Int)
    }

    func checkArray(_ array: [Any]) throws {
        XCTAssertEqual("yes", array[0] as? String)
        XCTAssertEqual(true, array[1] as? Bool)
        XCTAssertEqual(1, array[2] as? Int)
    }
}

private let authPayload = """
{
    "sessionJwt": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJiYXIiLCJuYW1lIjoiU3dpZnR5IE1jQXBwbGVzIiwiaWF0IjoxNTE2MjM5MDIyLCJpc3MiOiJmb28iLCJleHAiOjE2MDMxNzY2MTQsInBlcm1pc3Npb25zIjpbImQiLCJlIl0sInJvbGVzIjpbInVzZXIiXSwidGVuYW50cyI6eyJ0ZW5hbnQiOnsicGVybWlzc2lvbnMiOlsiYSIsImIiLCJjIl0sInJvbGVzIjpbImFkbWluIl19fX0.LEcNdzkdOXlzxcVNhvlqOIoNwzgYYfcDv1_vzF3awF8",
    "refreshJwt": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJxdXgiLCJuYW1lIjoiU3dpZnR5IE1jQXBwbGVzIiwiaWF0IjoxNTE2MjM5MDIyLCJpc3MiOiJmb28iLCJleHAiOjE2MDMxNzY2MTQsInBlcm1pc3Npb25zIjpbImQiLCJlIl0sInJvbGVzIjpbInVzZXIiXSwidGVuYW50cyI6eyJ0ZW5hbnQiOnsicGVybWlzc2lvbnMiOlsiYSIsImIiLCJjIl0sInJvbGVzIjpbImFkbWluIl19fX0.kgsfovgtFXwlr7Ev6XZ_BFMBSFNgTraw_G9WqAj78AA",
    "user": \(userPayload),
    "firstSeen": true
}
"""

private let userPayload = """
{
    "userId": "userId",
    "loginIds": ["loginId"],
    "name": "name",
    "picture": "picture",
    "email": "email",
    "verifiedEmail": true,
    "phone": "phone",
    "createdTime": 123,
    "middleName": "middleName",
    "familyName": "familyName",
    "customAttributes": {
        "a": "yes",
        "b": true,
        "c": 1,
        "d": null,
        "unnecessaryArray": [
            "yes",
            true,
            1,
            {
                "a": "yes",
                "b": true,
                "c": 1,
            }
        ]
    }
}
"""
