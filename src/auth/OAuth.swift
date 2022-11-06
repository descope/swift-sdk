
class OAuth: DescopeOAuth {
    let client: DescopeClient
    
    init(client: DescopeClient) {
        self.client = client
    }
    
    func start(provider: OAuthProvider, redirectURL: String?) async throws -> String {
        return try await client.oauthStart(provider: provider, redirectURL: redirectURL).url
    }
    
    func exchange(code: String) async throws -> DescopeSession {
        return try await client.oauthExchange(code: code).convert()
    }
}
