
class SSO: DescopeSSO {
    let client: DescopeClient
    
    init(client: DescopeClient) {
        self.client = client
    }
    
    func start(emailOrTenantName: String, redirectURL: String?, options: [SignInOptions]) async throws -> String {
        let (refreshJwt, loginOptions) = try options.convert()
        let response = try await client.ssoStart(emailOrTenantName: emailOrTenantName, redirectURL: redirectURL, refreshJwt: refreshJwt, options: loginOptions)
        return response.url
    }
    
    func exchange(code: String) async throws -> AuthenticationResponse {
        return try await client.ssoExchange(code: code).convert()
    }
}
