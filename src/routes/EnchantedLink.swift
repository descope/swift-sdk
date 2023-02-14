
import Foundation

class EnchantedLink: DescopeEnchantedLink {
    let client: DescopeClient
    
    init(client: DescopeClient) {
        self.client = client
    }
    
    func signUp(loginId: String, user: User, uri: String?) async throws -> DescopeSession {
        let response = try await client.enchantedLinkSignUp(loginId: loginId, user: user, uri: uri)
        return try await pollForSession(response.pendingRef)
    }
    
    func signIn(loginId: String, uri: String?) async throws -> DescopeSession {
        let response = try await client.enchantedLinkSignIn(loginId: loginId, uri: uri)
        return try await pollForSession(response.pendingRef)
    }
    
    func signUpOrIn(loginId: String, uri: String?) async throws -> DescopeSession {
        let response = try await client.enchantedLinkSignUpOrIn(loginId: loginId, uri: uri)
        return try await pollForSession(response.pendingRef)
    }
    
    func updateEmail(_ email: String, loginId: String, uri: String?, refreshJwt: String) async throws {
        try await client.enchantedLinkUpdateEmail(email, loginId: loginId, uri: uri, refreshJwt: refreshJwt)
    }
    
    private func pollForSession(_ pendingRef: String) async throws -> DescopeSession {
        let pollingEndsAt = Date() + 600 // 10 minute polling window
        while Date() < pollingEndsAt {
            do {
                return try await client.enchantedLinkPendingSession(pendingRef: pendingRef).convert()
            } catch DescopeError.enchantedLinkPending {
                try await Task.sleep(nanoseconds: NSEC_PER_SEC)
            }
        }
        throw DescopeError.enchantedLinkExpired
    }
}
