
import Foundation

private let defaultPollDuration: TimeInterval = 2 /* mins */ * 60 /* secs */

class EnchantedLink: DescopeEnchantedLink {
    let client: DescopeClient
    
    init(client: DescopeClient) {
        self.client = client
    }
    
    func signUp(loginId: String, user: User, uri: String?) async throws -> EnchantedLinkResponse {
        return try await client.enchantedLinkSignUp(loginId: loginId, user: user, uri: uri).convert()
    }
    
    func signIn(loginId: String, uri: String?) async throws -> EnchantedLinkResponse {
        return try await client.enchantedLinkSignIn(loginId: loginId, uri: uri).convert()
    }
    
    func signUpOrIn(loginId: String, uri: String?) async throws -> EnchantedLinkResponse {
        return try await client.enchantedLinkSignUpOrIn(loginId: loginId, uri: uri).convert()
    }
    
    func updateEmail(_ email: String, loginId: String, uri: String?, refreshJwt: String) async throws -> EnchantedLinkResponse {
        return try await client.enchantedLinkUpdateEmail(email, loginId: loginId, uri: uri, refreshJwt: refreshJwt).convert()
    }
    
    func checkForSession(pendingRef: String) async throws -> DescopeSession {
        return try await client.enchantedLinkPendingSession(pendingRef: pendingRef).convert()
    }
    
    func pollForSession(pendingRef: String, timeout: TimeInterval?) async throws -> DescopeSession {
        let pollingEndsAt = Date() + (timeout ?? defaultPollDuration)
        // use repeat to ensure we always check at least once
        while true {
            do {
                // ensure that the async task hasn't been cancelled
                try Task.checkCancellation()
                // check for the session once, any errors not specifically handled
                // below are intentionally let through to the calling code
                return try await checkForSession(pendingRef: pendingRef)
            } catch DescopeError.enchantedLinkPending {
                // sleep for a second before checking again
                try await Task.sleep(nanoseconds: NSEC_PER_SEC)
                // if the timer's expired then we throw as specific
                // client side error that can be handled appropriately
                // by the calling code
                guard Date() < pollingEndsAt else { throw DescopeError.enchantedLinkExpired }
            } catch let error as DescopeError where error == .networkError {
                // we managed to start the enchanted link authentication
                // so any network errors we get now are probably temporary
                try await Task.sleep(nanoseconds: NSEC_PER_SEC)
                // if the timer's expired then we rethrow the network
                // error as that was probably the cause, rather than the
                // user not verifying the enchanted link email
                guard Date() < pollingEndsAt else { throw error }
            }
        }
    }
}

private extension DescopeClient.EnchantedLinkResponse {
    func convert() -> EnchantedLinkResponse {
        return EnchantedLinkResponse(linkId: linkId, pendingRef: pendingRef, maskedEmail: maskedEmail)
    }
}
