
class Auth: DescopeAuth {
    let client: DescopeClient
    
    init(client: DescopeClient) {
        self.client = client
    }
    
    func me(refreshJwt: String) async throws -> DescopeUser {
        return try await client.me(refreshJwt: refreshJwt).convert()
    }

    func refreshSession(refreshJwt: String) async throws -> RefreshResponse {
        return try await client.refresh(refreshJwt: refreshJwt).convert()
    }

    func logout(refreshJwt: String) async throws {
        try await client.logout(refreshJwt: refreshJwt)
    }
}
