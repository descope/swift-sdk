
class OAuth: DescopeOAuth {
    let client: DescopeClient
    
    init(client: DescopeClient) {
        self.client = client
    }
    
    func start(provider: OAuthProvider, redirectURL: String?, options: [SignInOptions]) async throws -> String {
        let (refreshJwt, loginOptions) = try options.convert()
        let response = try await client.oauthStart(provider: provider, redirectURL: redirectURL, refreshJwt: refreshJwt, options: loginOptions)
        return response.url
    }
    
    func exchange(code: String) async throws -> AuthenticationResponse {
        return try await client.oauthExchange(code: code).convert()
    }
}
