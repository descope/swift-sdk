
class SSO: DescopeSSO {
    let client: DescopeClient
    
    init(client: DescopeClient) {
        self.client = client
    }
    
    func start(emailOrTenantName: String, redirectUrl: String?) async throws -> String {
        return try await client.ssoStart(emailOrTenantName: emailOrTenantName, redirectUrl: redirectUrl).url
    }
    
    func exchange(code: String) async throws -> [DescopeToken] {
        return try await client.ssoExchange(code: code).tokens()
    }
}
