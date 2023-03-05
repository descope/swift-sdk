
class Password: DescopePassword {
    let client: DescopeClient
    
    init(client: DescopeClient) {
        self.client = client
    }
    
    func signUp(loginId: String, user: User, password: String) async throws -> DescopeSession {
        return try await client.passwordSignUp(loginId: loginId, user: user, password: password).convert()
    }
    
    func signIn(loginId: String, password: String) async throws -> DescopeSession {
        return try await client.passwordSignIn(loginId: loginId, password: password).convert()
    }
}
