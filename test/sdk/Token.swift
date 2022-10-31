
import XCTest
@testable import DescopeKit

private let jwt = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IlN3aWZ0eSBNY0FwcGxlcyIsImlhdCI6MTUxNjIzOTAyMiwiaXNzIjoiUDEyMyIsImV4cCI6MTYwMzE3NjYxNCwicGVybWlzc2lvbnMiOlsiZCIsImUiXSwicm9sZXMiOlsidXNlciJdLCJ0ZW5hbnRzIjp7InRlbmFudCI6eyJwZXJtaXNzaW9ucyI6WyJhIiwiYiIsImMiXSwicm9sZXMiOlsiYWRtaW4iXX19fQ.kY-MLyIv1qhPzcCxyI2_1vP2lmKfqLvcEIwQZFPON10"

class TestToken: XCTestCase {
    func testTokenDecoding() throws {
        let token: Token = try Token(jwt: jwt)
        
        // Basic Fields
        XCTAssertEqual(jwt, token.jwt)
        XCTAssertEqual("1234567890", token.id)
        XCTAssertEqual("P123", token.projectId)
        
        // Expiration
        XCTAssertNotNil(token.expiresAt)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy"
        XCTAssertEqual("20.10.2020", dateFormatter.string(from: token.expiresAt!))
        XCTAssertTrue(token.isExpired)

        // Custom Claims
        XCTAssertEqual(1, token.claims.count)
        XCTAssertEqual("Swifty McApples", token.claims["name"] as! String)
        
        // Roles & Permissions
        let permissions = token.permissions(forTenant: nil)
        XCTAssertEqual(["d", "e"], permissions)
        let roles = token.roles(forTenant: nil)
        XCTAssertEqual(["user"], roles)
        
        // Roles & Permissions
        let tenantPermissions = token.permissions(forTenant: "tenant")
        XCTAssertEqual(["a", "b", "c"], tenantPermissions)
        let tenantRoles = token.roles(forTenant: "tenant")
        XCTAssertEqual(["admin"], tenantRoles)
        XCTAssertEqual([], token.permissions(forTenant: "no-such-tenant"))
    }
}


