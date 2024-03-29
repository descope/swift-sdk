
import XCTest
@testable import DescopeKit

private let jwt = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJiYXIiLCJuYW1lIjoiU3dpZnR5IE1jQXBwbGVzIiwiaWF0IjoxNTE2MjM5MDIyLCJpc3MiOiJmb28iLCJleHAiOjE2MDMxNzY2MTQsInBlcm1pc3Npb25zIjpbImQiLCJlIl0sInJvbGVzIjpbInVzZXIiXSwidGVuYW50cyI6eyJ0ZW5hbnQiOnsicGVybWlzc2lvbnMiOlsiYSIsImIiLCJjIl0sInJvbGVzIjpbImFkbWluIl19fX0.LEcNdzkdOXlzxcVNhvlqOIoNwzgYYfcDv1_vzF3awF8"

class TestAccessKey: XCTestCase {
    func testTokenDecoding() async throws {
        let descope = DescopeSDK.mock()

        MockHTTP.push(json: ["sessionJwt": jwt]) { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.allHTTPHeaderFields?["Authorization"], "Bearer projId:key")
            XCTAssertEqual(request.httpBody, Data("{}".utf8))
        }
        
        let token = try await descope.accessKey.exchange(accessKey: "key")
        XCTAssertEqual(jwt, token.jwt)
        XCTAssertEqual("bar", token.entityId)
        XCTAssertEqual("foo", token.projectId)
        XCTAssertTrue(token.isExpired)
    }
}
