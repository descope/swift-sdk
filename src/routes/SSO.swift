
class SSO: DescopeSSO {
    let client: DescopeClient
    
    init(client: DescopeClient) {
        self.client = client
    }
    
    func start(emailOrTenantName: String, redirectURL: String?) async throws -> String {
        return try await client.ssoStart(emailOrTenantName: emailOrTenantName, redirectURL: redirectURL).url
    }
    
    func exchange(code: String) async throws -> DescopeSession {
        return try await client.ssoExchange(code: code).convert()
    }
}
