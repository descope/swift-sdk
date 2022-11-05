
class TOTP: DescopeTOTP {
    let client: DescopeClient
    
    init(client: DescopeClient) {
        self.client = client
    }

    func signUp(identifier: String, user: User) async throws -> TOTPResponse {
        let resp = try await client.totpSignUp(identifier: identifier, user: user)
        return TOTPResponse(provisioningURL: resp.provisioningURL, key: resp.key)
    }
    
    func verify(identifier: String, code: String) async throws -> DescopeSession {
        return try await client.totpVerify(identifier: identifier, code: code).convert()
    }
    
    func update(identifier: String, refreshToken: String) async throws {
        try await client.totpUpdate(identifier: identifier, refreshToken: refreshToken)
    }
}
