import XCTest
@testable import DescopeKit

struct UserResponse: Decodable {
    var id: Int
}

final class HttpTests: XCTestCase {
    func testSimpleHttp() async throws {
        // Simple JSON response
        let client = HttpClient(baseURL: "https://jsonplaceholder.typicode.com")
        let resp: UserResponse = try await client.get("users/1")
        XCTAssertEqual(resp.id, 1)
    }
}
