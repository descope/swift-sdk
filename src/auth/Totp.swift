
import Foundation

class TOTP: DescopeTOTP {
    let client: DescopeClient
    
    init(client: DescopeClient) {
        self.client = client
    }

    func signUp(identifier: String, user: User) async throws -> TOTPResponse {
        let resp = try await client.totpSignUp(identifier: identifier, user: user)
        return TOTPResponse(provisioningURL: resp.provisioningURL, key: resp.key)
    }
    
    func verify(identifier: String, code: String) async throws -> [Token] {
        let response = try await client.totpVerify(identifier: identifier, code: code)
        let jwts = [response.sessionJwt, response.refreshJwt].compactMap { $0 }
        return try jwts.map { try _Token(jwt: $0) }
    }
    
    func update(identifier: String, refreshToken: String) async throws {
        try await client.totpUpdate(identifier: identifier, refreshToken: refreshToken)
    }
}
