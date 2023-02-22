
import Foundation

class EnchantedLink: DescopeEnchantedLink {
    
    let client: DescopeClient
    
    init(client: DescopeClient) {
        self.client = client
    }
    
    func signUp(loginId: String, user: User, uri: String?) async throws -> EnchantedLinkResponse {
        let response = try await client.enchantedLinkSignUp(loginId: loginId, user: user, uri: uri)
        return EnchantedLinkResponse(linkId: response.linkId, pendingRef: response.pendingRef)
    }
    
    func signIn(loginId: String, uri: String?) async throws -> EnchantedLinkResponse {
        let response = try await client.enchantedLinkSignIn(loginId: loginId, uri: uri)
        return EnchantedLinkResponse(linkId: response.linkId, pendingRef: response.pendingRef)
    }
    
    func signUpOrIn(loginId: String, uri: String?) async throws -> EnchantedLinkResponse {
        let response = try await client.enchantedLinkSignUpOrIn(loginId: loginId, uri: uri)
        return EnchantedLinkResponse(linkId: response.linkId, pendingRef: response.pendingRef)
    }
    
    func verify(token: String, pendingRef: String) async throws -> DescopeSession {
        return try await client.enchantedLinkVerify(token: token, pendingRef: pendingRef).convert()
        // return try await pollForSession(pendingRef: pendingRef)
    }
    
    func updateEmail(email: String, loginId: String, uri: String?, refreshJwt: String) async throws -> EnchantedLinkResponse {
        return try await client.enchantedLinkUpdateEmail(email: email, loginId: loginId, uri: uri, refreshJwt: refreshJwt).convert()
    }
    
    internal func pollForSession(pendingRef: String) async throws -> DescopeSession {
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
