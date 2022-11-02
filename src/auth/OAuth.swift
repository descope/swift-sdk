
class OAuth: DescopeOAuth {
    let client: DescopeClient
    
    init(client: DescopeClient) {
        self.client = client
    }
    
    func start(provider: OAuthProvider, redirectUrl: String?) async throws -> String {
        let res = try await client.oauthStart(provider: provider, redirectUrl: redirectUrl)
        return res.url
    }
    
    func exchange(code: String) async throws -> [DescopeToken] {
        return try await client.oauthExchange(code: code).tokens()
    }
}
