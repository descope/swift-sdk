import XCTest
@testable import DescopeKit

class TestAuth: XCTestCase {
    func testMe() async throws {
        let descope = DescopeSDK.mock()

        MockHTTP.push(body: mePayload) { request in
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.allHTTPHeaderFields?["Authorization"], "Bearer projId:jwt")
        }

        let user = try await descope.auth.me(refreshJwt: "jwt")
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

private let mePayload = """
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
