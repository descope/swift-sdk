
class TOTP: DescopeTOTP {
    let client: DescopeClient
    
    init(client: DescopeClient) {
        self.client = client
    }

    func signUp(loginId: String, user: User) async throws -> TOTPResponse {
        let resp = try await client.totpSignUp(loginId: loginId, user: user)
        return TOTPResponse(provisioningURL: resp.provisioningURL, image: resp.image, key: resp.key)
    }
    
    func verify(loginId: String, code: String) async throws -> DescopeSession {
        return try await client.totpVerify(loginId: loginId, code: code).convert()
    }
    
    func update(loginId: String, refreshJwt: String) async throws -> TOTPResponse {
        let resp = try await client.totpUpdate(loginId: loginId, refreshJwt: refreshJwt)
        return TOTPResponse(provisioningURL: resp.provisioningURL, image: resp.image, key: resp.key)
    }
}
