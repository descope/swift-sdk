
import Foundation

class MagicLink: DescopeMagicLink {
    let client: DescopeClient
    
    init(client: DescopeClient) {
        self.client = client
    }
    
    // MARK: - Same-Device
    
    func signUp(with method: DeliveryMethod, loginId: String, user: User, uri: String?) async throws {
        try await callSignUp(with: method, loginId: loginId, user: user, uri: uri)
    }
    
    func signIn(with method: DeliveryMethod, loginId: String, uri: String?) async throws {
        try await callSignIn(with: method, loginId: loginId, uri: uri)
    }
    
    func signUpOrIn(with method: DeliveryMethod, loginId: String, uri: String?) async throws {
        try await callSignUpOrIn(with: method, loginId: loginId, uri: uri)
    }
    
    func updateEmail(_ email: String, loginId: String, refreshToken: String) async throws {
        try await client.magicLinkUpdateEmail(email, loginId: loginId, refreshToken: refreshToken)
    }
    
    func updatePhone(_ phone: String, with method: DeliveryMethod, loginId: String, refreshToken: String) async throws {
        try await client.magicLinkUpdatePhone(phone, with: method, loginId: loginId, refreshToken: refreshToken)
    }
    
    func verify(token: String) async throws -> DescopeSession {
        return try await client.magicLinkVerify(token: token).convert()
    }

    // MARK: - Cross-Device
    
    func signUpCrossDevice(with method: DeliveryMethod, loginId: String, user: User, uri: String?) async throws -> DescopeSession {
        let pendingRef = try await callSignUp(with: method, loginId: loginId, user: user, uri: uri)
        return try await pollForSession(pendingRef)
    }
    
    func signInCrossDevice(with method: DeliveryMethod, loginId: String, uri: String?) async throws -> DescopeSession {
        let pendingRef = try await callSignIn(with: method, loginId: loginId, uri: uri)
        return try await pollForSession(pendingRef)
    }
    
    func signUpOrInCrossDevice(with method: DeliveryMethod, loginId: String, uri: String?) async throws -> DescopeSession {
        let pendingRef = try await callSignUpOrIn(with: method, loginId: loginId, uri: uri)
        return try await pollForSession(pendingRef)
    }
    
    // MARK: - Utility Methods
    
    @discardableResult
    private func callSignUp(with method: DeliveryMethod, loginId: String, user: User, uri: String?) async throws -> String {
        let response = try await client.magicLinkSignUp(with: method, loginId: loginId, user: user, uri: uri)
        return response.pendingRef
    }
    
    @discardableResult
    private func callSignIn(with method: DeliveryMethod, loginId: String, uri: String?) async throws -> String {
        let response = try await client.magicLinkSignIn(with: method, loginId: loginId, uri: uri)
        return response.pendingRef
    }
    
    @discardableResult
    private func callSignUpOrIn(with method: DeliveryMethod, loginId: String, uri: String?) async throws -> String {
        let response = try await client.magicLinkSignUpOrIn(with: method, loginId: loginId, uri: uri)
        return response.pendingRef
    }
    
    private func pollForSession(_ pendingRef: String) async throws -> DescopeSession {
        let pollingEndsAt = Date() + 600 // 10 minute polling window
        while pollingEndsAt > Date() {
            do {
                return try await client.magicLinkPendingSession(pendingRef: pendingRef).convert()
            } catch {}
            try await Task.sleep(nanoseconds: NSEC_PER_SEC)
        }
        
        throw DescopeError.magicLinkExpired
    }
}
